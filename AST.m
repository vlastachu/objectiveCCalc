#include <math.h>
#import "AST.h"

@implementation RootNode
@synthesize isReduceble;
@synthesize lastExpression = _lastExpression;
@synthesize statements = _statements;
- (BOOL) isReduceble{
	return YES;
}

- (RootNode*) init{
    self = [super init];
    if(self){
        _statements = [NSMutableDictionary new];
    }
    return self;
}

- (RootNode*) appendAssignmentWithVarName: (NSString*)varName
                  andExpression: (Expression*) expr{
    [_statements setObject: expr forKey: varName];
    return self;
}

- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
	NSEnumerator *e = [_statements objectEnumerator];
	id statement;
	while(statement = [e nextObject]){
		[statement reduceWithApproximation: isApproximate];
	}
    [_lastExpression reduceWithApproximation: isApproximate];
	return self;
}
- (NSString*) toString{
	NSEnumerator *e = [_statements keyEnumerator];
	id key;
	NSMutableString strBuilder = [NSMutableString new];
	while(key = [e nextObject]){
		[strBuilder appendFormat: @"%@ = %@\n", key,
            [[_statements objectForKey: key] toString]];
	}
    [strBuilder appendFormat: @"%@",
        [_lastExpression toString]];
	NSString *ret = [NSString stringWithString: strBuilder];
	[strBuilder release];
	return ret;
}
@end

@implementation BrokenExpression
	@synthesize isReduceble;
	- (BOOL) isReduceble{
		return NO;
	}
@end


@implementation Variable
- (Variable*)initWithName: (NSString*) name andRoot: (RootNode*)rootNode{
    self = [super init];
    if(self){
        _varName = name;
        _expr = [rootNode.statements objectForKey:name];
    }
    return self;
}
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
    if(_expr && _expr.isReduceble)
        return [_expr reduceWithApproximation: isApproximate];
    return self;
}
- (NSString*) toString{
    return [NSString stringWithFormat: @"%@", _varName];
}
@end

@implementation Number
@synthesize isReduceble; 
- (BOOL) isReduceble{
    return YES;
}
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
    return self;
}

- (Number*) initWithFloat: (double) n;
    self = [super init];
    if(self){
        _num = n;
    }
    return self;
}

- (NSString*) toString{
    return [NSString stringWithFormat: @"%lf", _num];
}
@end    

@implementation PI
@synthesize isReduceble;
- (BOOL) isReduceble{
    return YES;
}
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
    _isApproximate = isApproximate;
    return self;
}

- (Number*) init: (double) n;
    self = [super init];
    if(self){

    }
    return self;
}

- (NSString*) toString{
    if(_isApproximate)
        return [NSString stringWithFormat: @"%lf", pi];//TODO!!
    else
        return [NSString stringWithFormat: @"PI"];
}
@end  

@implementation EXP
@synthesize isReduceble;
- (BOOL) isReduceble{
    return YES;
}
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
    _isApproximate = isApproximate;
    return self;
}

- (Number*) init: (double) n;
    self = [super init];
    if(self){

    }
    return self;
}

- (NSString*) toString{
    if(_isApproximate)
        return [NSString stringWithFormat: @"%lf", pi];//TODO!!
    else
        return [NSString stringWithFormat: @"E"];
}
@end  


@implementation BinaryFunction
- (BinaryFunction*) initWithLeftArgument: (Expression*) left rightArgument:(Expression*) right{
    self = [super init];
    if(self){
        _left = left;
        _right = right;
    }
}
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
    if([_left isReduceble] && [right isReduceble])
        return [Number initWithFloat:[self 
            applyForLeft:
                [_left reduceWithApproximation: isApproximate]
            right:
                [_right reduceWithApproximation: isApproximate]
            ]];
    return self;
}
- (NSString*) toString{
    return [NSString stringWithFormat:@"%@(%@, %@)",
        [self strFunction],
        [_left toString], 
        [_right toString]];
}

@end

@implementation BinaryOperator
    - (NSString*) toString{
        return [NSString stringWithFormat:@"(%@ %@ %@)",
            [_left toString], 
            [self strFunction],
            [_right toString]];
    }
@end

@implementation Addition
    + (double) applyForLeft: (double)left right: (double)right{
        return left + right;
    }
    + (NSString) strFunction{
        return @"+";
    }
@end

@implementation Substraction
    + (double) applyForLeft: (double)left right: (double)right{
        return left - right;
    }
    + (NSString) strFunction{
        return @"-";
    }
@end

@implementation Multiplication
    + (double) applyForLeft: (double)left right: (double)right{
        return left * right;
    }
    + (NSString) strFunction{
        return @"*";
    }
@end

@implementation Division
    + (double) applyForLeft: (double)left right: (double)right{
        return left / right;
    }
    + (NSString) strFunction{
        return @"/";
    }
@end

@implementation Involution
    + (double) applyForLeft: (double)left right: (double)right{
        return pow(left, right);
    }
    + (NSString) strFunction{
        return @"**";
    }
@end

@implementation IntegerDivision
    + (double) applyForLeft: (double)left right: (double)right{
        return (int)(floor(left) / floor(right));
    }
    + (NSString) strFunction{
        return @"\\";
    }
@end

@implementation Modulation
    + (double) applyForLeft: (double)left right: (double)right{
        return (int)(floor(left) % floor(right));
    }
    + (NSString) strFunction{
        return @"%";
    }
@end

@implementation Min
    + (double) applyForLeft: (double)left right: (double)right{
        if(left < right)
            return left;
        return right;
    }
    + (NSString) strFunction{
        return @"Min";
    }
@end

@implementation Max
    + (double) applyForLeft: (double)left right: (double)right{
        if(left > right)
            return left;
        return right;
    }
    + (NSString) strFunction{
        return @"Max";
    }
@end

@implementation UnaryFunction
    - (UnaryFunction*) initWithArgument: (Expression*) arg{
        self = [super init];
        if(self){
            _expr = arg;
        }
        return self;
    }
    - (RootNode*) reduceWithApproximation: (BOOL) isApproximate{
        if([_left isReduceble] && [right isReduceble])
            return [Number initWithFloat:[self 
                applyForArg:
                    [_expr reduceWithApproximation: isApproximate]]];
        return self;
    }
    - (NSString*) toString{
        return [NSString stringWithFormat:@"%@(%@)",
            [self strFunction],
            [_expr toString]];
    }
@end


@implementation Negation
    + (double) applyForArg: (double)arg{
        return -arg;
    }
    + (NSString) strFunction{
        return @"-";
    }
@end


@implementation Negation
    + (double) applyForArg: (double)arg{
        return -arg;
    }
    + (NSString) strFunction{
        return @"-";
    }
@end

@implementation Sin
    + (double) applyForArg: (double)arg{
        return sin(arg);
    }
    + (NSString) strFunction{
        return @"sin";
    }
@end

@implementation Cos
    + (double) applyForArg: (double)arg{
        return cos(arg);
    }
    + (NSString) strFunction{
        return @"cos";
    }
@end

@implementation Tg
    + (double) applyForArg: (double)arg{
        return tan(arg);
    }
    + (NSString) strFunction{
        return @"tg";
    }
@end

@implementation Ctg
    + (double) applyForArg: (double)arg{
        return 1/tan(arg);
    }
    + (NSString) strFunction{
        return @"ctg";
    }
@end

@implementation Abs
    + (double) applyForArg: (double)arg{
        return abs(arg);
    }
    + (NSString) strFunction{
        return @"abs";
    }
@end

@implementation Sqrt
    + (double) applyForArg: (double)arg{
        return sqrt(arg);
    }
    + (NSString) strFunction{
        return @"sqrt";
    }
@end

    

