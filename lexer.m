#import "lexer.h"


@implementation Lexeme
@synthesize token = _token;
@synthesize string = _string;
@synthesize line = _line;
@synthesize position = _position;

- initWithToken: (Token)token string: (NSString*) str source: (NSString*) source
    line: (int)line andPosition: (int)pos{
    self = [super init];
    if(self){
        _token = token;
        _string = string;
        _line = line;
        _position = position;
        _source = source;
    }
    return self;
}

- (void)logAtLexeme{
    NSLog([NSString stringWithFormat: @"line: %i; column: %i symbol: %@",
        _line, _position, _string]);
    NSArray* lines = [_source componentsSeparatedByString: @"\n"];
    NSLog([lines objectAtIndex: _line]);
    char *posPoint = malloc(sizeof(char)*(_pos+2));
    for (int i = 0; i < _position; ++i)
    {
        posPoint[i] = ' ';
    }
    posPoint[_position] = '^';
    posPoint[_position+1] = '\0';
    NSLog([NSString stringWithString: posPoint]);
    [lines release];
    free(posPoint);
}

- (void)logAtLexemeTo: (Lexeme*) endlex{
    NSLog([NSString stringWithFormat: @"line: %i; column: %i symbol: %@",
        _line, _position, _string]);
    NSArray* lines = [_source componentsSeparatedByCharactersInSet: 
                            [NSCharacterSet newlineCharacterSet]];
    NSLog([lines objectAtIndex: _line]);
    char *posPoint = malloc(sizeof(char)*(endlex.position+2));
    for (int i = 0; i < endlex.position; ++i)
    {
        if(i < _position)
            posPoint[i] = ' ';
        else
            posPoint[i] = '-';
    }
    posPoint[_position] = '^';
    posPoint[endlex.position] = '^';
    posPoint[endlex.position+1] = '\0';
    NSLog([NSString stringWithString: posPoint]);
    [lines release];
    free(posPoint);
}


@end

@implementation Lexer
    -(char) nextChar{
        return _sourceBuf[_cursor++];
    }

    -(char) curChar{
        return _sourceBuf[_cursor];
    }
    
    -(void) skipSpaces{
        while([self isSpace: [self nextChar]]){
            //nothing to do
        }
    }

    -(BOOL) isSpace: char c{
        return c == ' ' || c == '\n' || c == '\t';
    }

    -(BOOL) isLetter: char c{
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
    }
    
    -(BOOL) isDigit: char c{
        return (c >= '0' && c <= '9');
    }

    -(BOOL) isIdentifierHead: char c{
        return [self isLetter: c];
    }


    -(BOOL) isIdentifierTail: char c{
       return [self isLetter: c] || [self isDigit: c];
    }

    - (id) initWithFileContent: (NSString *) file{
        if(self = [super init]){
            //let rid from different newlines problem
            //once and forever
            _source = [str stringByReplacingOccurrencesOfString:@"\r"
                                     withString:@"\n"];
            _source = [str stringByReplacingOccurrencesOfString:@"\n\n"
                                     withString:@"\n"];;
            _prevCharPos = 0;
            _line = 0;

            NSUInteger len = [_source length];
            _sourceBuf = calloc(len+1, 1);
            [_source getCharacters:_sourceBuf range:NSMakeRange(0, len)];

        }
        return self;
    }

    -(void) log: (NSString*) str{
        NSLog([NSString stringWithFormat: @"lexical error - line: %i; column: %i",
        _curLine, _prevCharPos]);
        NSLog(@"%@",str);
    }

    -(Lexeme*) newLexemeWithToken: (Token)token andString: (NSString*)str{ 
        return [[Lexeme alloc]  initWithToken: token string: (NSString*) str 
                        source: _source
                        line: _line andPosition: _prevCharPos];
    }

    - (Lexeme*) scanForIdentifierBeginWith: (char)c{
        char identifier[100] = {0};
        identifier[0] = c;
        //rewrite to memcpy
        for(int i = 1; i < 100; i++){
            c = [self nextChar];
            if([self isIdentifierTail: c]){
                identifier[i] = c;
            }
            else break;
        }
        if([self isIdentifierTail: [self curChar]]){
            [self log:@"Identifier too long. Cut to 100 symbols."]
            while([self isIdentifierTail: c])
                c = [self nextChar]; 
        }
        NSString *str = [[NSString alloc] initWithUTF8String: identifier];
        Token token = [tokenStringDict indexOfObject: str];
        if(not token){
            token = T_Identifier;
        }
        return [self newLexemeWithToken: token andString: str];
    }
    - (void)skipManyDigits{
        char c;
        do{
            c = [self nextChar];
        }
        while([self isDigit: c]);
    }

    - (Lexeme*) scanForNumberBeginWith: (char)c{
        //Integer part:
        [self skipManyDigits];
        if([self curChar] == '.'){
            [self nextChar];
            [self skipManyDigits];
        }
        char* begin = _sourceBuf + _prevCharPos;
        char* end = _sourceBuf + _cursor;
        int length = end - begin;
        //TODO chaeck too big length. Or float parser should do it?
        char* buf = malloc(length*sizeof(char));
        memcpy(buf, begin, length*sizeof(char));
        NSString *str = [[NSString alloc] initWithUTF8String: buf];
        return [self newLexemeWithToken: T_Number andString: str];
    }

    -(Lexeme*) checkOneCharToken: (char) c{
        char *_c = {c,0};
        NSString *str = [[NSString alloc] initWithUTF8String: _c];
        Token token = [tokenStringDict indexOfObject: str];
        if(token)
            return [self newLexemeWithToken: token andString: nil];
        else
            return nil;
    }

    - (Lexeme*) getNextToken{
        _prevCharPos = _cursor;
        [self skipSpaces];
        //
        char c;
        c = [self nextChar];

        if([self isIdentifierHead:c])
            return [self scanForIdentifierBeginWith: c];
        if([self isDigit: c])
            return [self scanForNumberBeginWith: c];
        //special case with asterisk
        if(c == '*')
            if([self curChar] == '*'){
                [self nextChar];
                return [self newLexemeWithToken: T_DblAsterisk andString: nil];
            }
            else{
                return [self newLexemeWithToken: T_Asterisk andString: nil];
            }
        if(not c)
            return [self newLexemeWithToken: T_EOF andString: nil];
        Lexeme *lexeme = [self checkOneCharToken: c];
        if(not lexeme){
            [self log:@"Can't determine token."];
            return [self getNextToken];
        }
        return lexeme;


    }

    - (void) dealloc{
        free(_sourceBuf);
    }

@end
