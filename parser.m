#import "AST.h"
#import "parser.h"
#import "lexer.h"



BOOL isFunction(Token token){
    return     token == T_Sin || token == T_Max 
            || token == T_Cos || token == T_Tg 
            || token == T_Ctg || token == T_Min 
            || token == T_Abs || token == T_Sqrt;
}

BOOL isOperator(Token token){
    return token == T_Plus     || token == T_Minus 
        || token == T_Asterisk || token == T_DblAsterisk 
        || token == T_Percent  || token == T_Slash 
        || token == T_Backslash;
}

unsigned int getFunctionArgsCount(Token token){
    switch (token) {
        case T_Sin:
        case T_Cos:
        case T_Tg:
        case T_Ctg:
        case T_Abs:
        case T_Sqrt:
            return 1;
        case T_Min:
        case T_Max:
            return 2;
        default:
            return 0;
    }
    return 0;
}

//switch is better solution than building dictionary of objects 
unsigned int getOperatorPriority(Token token){
    switch (token) {
        case T_Plus:
        case T_Minus:
            return 1;
        case T_Asterisk:
        case T_Slash:
        case T_Backslash:
        case T_Percent:
            return 2;
        case T_DblAsterisk:
            return 3;
        default:
        //undefined behavior
            return 0;
    }
}

BOOL isLeftAssociated(Token token){
    //there is only one right associated operator
    if(token == T_DblAsterisk)
        return NO;
    else 
        return YES;
}


@implementation Parser

- (Parser*)initWithString: (NSString*)source{
    self = [super init];
    if(self){
        _source = source;
        _lexems = [NSMutableArray new];
    }
    return self;
}

- (BOOL)mustBeToken: (Token)token at: (int)position{
    if([_lexems objectAtIndex: startPos].position.token == token)
        return YES;
    else{
        [[_lexems objectAtIndex: startPos] logAtLexeme];
        NSLog(@"%@ expected", tokenToString(token));
        return NO;
    }
}

//return position of closing paren and 0 if not found
- (int)findClosingParenAt: (int)startPos until: (int) endPos{
    int parenCount = 1;
    for (int i = startPos; i < endPos; ++i)
    {
        if([_lexems objectAtIndex: i].token == T_LParen)
            parenCount++;
        else if ([_lexems objectAtIndex: i].token == T_RParen)
            parenCount--;
        if(parenCount == 0)
            return i;
    }
    [[_lexems objectAtIndex: startPos] logAtLexemeTo: [_lexems objectAtIndex: endPos]];
    NSLog(@"'%@' expected", tokenToString(T_RParen));
    return 0;
}

//comma may be found only in function usage 
//so we search for comma at same paren level
- (int)findTopLevelCommaAt: (int)startPos until: (int) endPos{
    int parenCount = 1;
    for (int i = startPos; i < endPos; ++i)
    {
        if([_lexems objectAtIndex: i].token == T_Comma && parenCount == 1)
            return i;
        if([_lexems objectAtIndex: i].token == T_LParen)
            parenCount++;
        else if ([_lexems objectAtIndex: i].token == T_RParen)
            parenCount--;
    }
    [[_lexems objectAtIndex: startPos] logAtLexemeTo: [_lexems objectAtIndex: endPos]];
    NSLog(@"'%@' expected. Function need more arguments.", tokenToString(T_RParen));
    return 0;
}

//waiting for term at Lexems[startPos] Token 
//which can be long chain of tokens sin(cos(tg(...)))
//but strongly not longer than endPos

- (Expression*)parseFunction: (Lexeme)functionLexeme at: (int*)startPos until: (int)endPos{
    if(*startPos == endPos){
        [[_lexems objectAtIndex: *startPos] logAtLexeme];
        NSLog(@"function arguments expected", tokenToString(token));
        return [[BrokenExpression alloc] init];
    }
    int pos = *startPos;
    int closingParenPos = [self findClosingParenAt: (pos + 1) until: endPos];
    *startPos = closingParenPos + 1;
    //if no open paren or closing paren not found
    if(not([self mustBeToken: T_LParen at: pos] && closingParenPos))
        return [[BrokenExpression alloc] init];
    pos++; //skip opening paren
    //There is only 2 cases.
    Expression *arg1, *arg2;
    if(getFunctionArgsCount(functionLexeme.token) == 1){
        arg1 = [self parseExpressionFrom: pos to: closingParenPos];
        switch (Lexeme.token) {
            case T_Sin:  return [[Sin  alloc] initWithArgument: arg1];
            case T_Cos:  return [[Cos  alloc] initWithArgument: arg1];
            case T_Tg:   return [[Tg   alloc] initWithArgument: arg1];
            case T_Ctg:  return [[Ctg  alloc] initWithArgument: arg1];
            case T_Abs:  return [[Abs  alloc] initWithArgument: arg1];
            case T_Sqrt: return [[Sqrt alloc] initWithArgument: arg1];
        }
    }
    else if(getFunctionArgsCount(functionLexeme.token) == 2){
        int commaPos = [self findTopLevelCommaAt: pos until: closingParenPos];
        if(not commaPos)
            return [[BrokenExpression alloc] init];
        arg1 = [self parseExpressionFrom: pos until: commaPos];
        arg2 = [self parseExpressionFrom: (commaPos+1) until: closingParenPos]
        switch (Lexeme.token) {
            case T_Min: return [[Min alloc] initWithLeftArgument: arg1 rightArgument: arg2];
            case T_Max: return [[Max alloc] initWithLeftArgument: arg1 rightArgument: arg2];
        }   
    }
    assert(NO); //"unreachable fragment at parseFunction"
}

// Term ::= '(' Expr ')' | UnaryOperator Expr | Number | Var | PI | EXP | Function 
- (Expression*)parseTermAt: (int*)startPos until: (int)endPos{
    if(*startPos == endPos){
        [[_lexems objectAtIndex: *startPos] logAtLexeme];
        NSLog(@"any term expected", tokenToString(token));
        return [[BrokenExpression alloc] init];
    }
    Lexeme *first = [_lexems objectAtIndex: *startPos];
    (*startPos)++;
    if(isFunction(first.token)){
        return [self parseFunction: first at: startPos until: endPos];
    }
    switch (first.token) {
        case T_PI:
            return [[PI alloc] init];
        case T_EXP:
            return [[EXP alloc] init];
        case T_Number:
            return [[Number alloc] initWithFloat: [first.string floatValue]];
        case T_Identifier:
            return [[Variable alloc] initWithName: first.string andRoot: _root]
        case T_LParen:
            int closingParenPos = [self findClosingParenAt: (pos + 1) until: endPos];
            if(not closingParenPos)
                return [[BrokenExpression alloc] init];
            Expression *e = [self parseExpressionFrom: *startPos to: closingParenPos];
            *startPos = closingParenPos + 1;
            return e; 
        break;
        case T_Plus:
            //just skip
            return [self parseTermAt: startPos until: endPos];
        case T_Minus:
            return [[Negation alloc] initWithArgument: 
                [self parseTermAt: startPos until: endPos]];
    }
    assert(NO); // "unreachable fragment at parseTerm"
}

- (int) pushOperator: (Token)token toExpressionsStack: (NSMutableArray*) stack{
    assert([stack count] >= 2); // "not enough operands in stack"
    Expression *left, *right;
    left = [outputStack lastObject];
    [outputStack removeLastObject];
    right = [outputStack lastObject] ;
    [outputStack removeLastObject];
    switch (token) {
        case T_Plus:
            return [[Addition alloc] initWithLeftArgument: left rightArgument: right];
        case T_Minus:
            return [[Substraction alloc] initWithLeftArgument: left rightArgument: right];
        case T_Asterisk:
            return [[Multiplication alloc] initWithLeftArgument: left rightArgument: right];
        case T_DblAsterisk:
            return [[Involution alloc] initWithLeftArgument: left rightArgument: right];
        case T_Slash:
            return [[Division alloc] initWithLeftArgument: left rightArgument: right];
        case T_Backslash:
            return [[IntegerDivision alloc] initWithLeftArgument: left rightArgument: right];
        case T_Percent:
            return [[Modulation alloc] initWithLeftArgument: left rightArgument: right];
    }
    assert(NO); // "unreachable fragment at pushOperator"
}

//waiting for expression which strongly start at startPos and strongly end at endPos
// Expression ::= Term | Term BinOperator Expression
- (Expression*)parseExpressionFrom: (int)startPos to: (int)endPos{
    int position = startPos;
    //in most cases expression is one term
    Expression* term = [self parseTermAt: &position unless: endPos];
    if(position == endPos)
        return term;
    //in other case we need to parse binary operators 
    //Shunting-yard algorithm
    //stack of operator tokens (lexemes)
    NSMutableArray *operatorStack = [NSMutableArray new];
    //stack of expressions
    NSMutableArray *outputStack = [NSMutableArray new];
    Token operator1, operator2;
    do{
        operator1 = [_lexems objectAtIndex: position].token;
        if(not isOperator(operator1)){
            [[_lexems objectAtIndex: position] logAtLexeme];
            NSLog(@"any operator expected");
            [operatorStack release];
            [outputStack release]; //ETC!
            return [[BrokenExpression alloc] init];
        }
        while(operator2 = [operatorStack lastObject]){
            if( (isLeftAssociated(operator1) &&
                 getOperatorPriority(operator1) <= getOperatorPriority(operator2))
                || getOperatorPriority(operator1) < getOperatorPriority(operator2))
            {
                [self pushOperator: operator2 toExpressionsStack: outputStack];
                [operatorStack removeLastObject];
            }
            else break;
        }
        [operatorStack addObject: operator1];
        position++;
        if(position == endPos){
            [[_lexems objectAtIndex: position] logAtLexeme];
            NSLog(@"right operand expected");
            [operatorStack release];
            [outputStack release]; //ETC!
            return [[BrokenExpression alloc] init];
        }
        //where will be position if term is broken?
        term = [self parseTermAt: &position unless: endPos];
        [outputStack addObject: term];
    }while(position != endPos);
    while(operator1 = [operatorStack lastObject]){
        [self pushOperator: operator1 toExpressionsStack: outputStack];
        [operatorStack removeLastObject];
    }
    assert([stack count] >= 2) // "not enough operands in stack"
    term = [outputStack lastObject];
    [operatorStack release];
    [outputStack release];
    return term;
}

- (RootNode*)compileAST{
    //loop scan lexems
    Lexer *lexer = [[Lexer alloc] initWithSource: _source];
    Lexeme *lastLexeme;
    do{
        lastLexeme = [lexer getNextLexeme];
        [_lexems addObject: lastLexeme];
    }while(lastLexeme.token != T_EOF);
    //loop reading statements
    int i, statementStart, statementEnd;
    _root = [[RootNode alloc] init];
    for(int i = 0; i < [_lexems count]; i++){
        statementStart = i;
        while([_lexems objectAtIndex: i].token != T_Newline ||
            [_lexems objectAtIndex: i].token != T_EOF){
            //check if wrong assignment statement
            if(i != statementStart + 1 && 
                [_lexems objectAtIndex: i].token == T_Assign){
                [[_lexems objectAtIndex: i] logAtLexeme];
                NSLog(@"wrong assignment statement. There should be \"varName = expression\".");            
            }
            i++;
        }
        statementEnd = i;
        if([_lexems objectAtIndex: statementStart+1].token == T_Assign){
            [self mustBeToken: T_Identifier at: statementStart];
            NSString varName = [_lexems objectAtIndex: statementStart].string;
            Expression* expr = [self parseExpressionFrom: statementStart + 2
                                                      to: statementEnd];
            [root appendAssignmentWithVarName: varName andExpression: expr];
            _root.lastExpression = expr;
        }
        else{
            Expression* expr = [self parseExpressionFrom: statementStart
                                                      to: statementEnd];
            _root.lastExpression = expr;
        }
    }
    return _root;
}

@end