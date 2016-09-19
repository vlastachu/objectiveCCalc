/*
 * This classes represent Abstract Syntax Tree which is convenient to calculate.
 * Also these classes provide methods for calculating and string converting,
 * ie there is no specific module for calculation (compilation).
 */

#import <objc/Object.h>
#import <Foundation/Foundation.h>

//#typedef double numType //<cmath> using double so typedef is meaningless 

@protocol ASTNode
- (id<ASTNode>*) reduceWithApproximation: (BOOL) isApproximate;
//there is 'description' method, but it may be called implicitly
//that will cause unexpected effect
- (NSString*) toString;
@property (nonatomic, readonly, getter=isReduceble) BOOL isReduceble;
@end


@interface Expression: NSObject<ASTNode>{}
- (id<ASTNode>*) reduceWithApproximation: (BOOL) isApproximate;
- (NSString*) toString;
@end

@interface RootNode: NSObject<ASTNode>{
    Expression* _lastExpression;
    NSMutableDictionary* _statements;
}
- (RootNode*) init;
- (RootNode*) appendAssignmentWithVarName: (NSString*)varName
              andExpression: (Expression*) expr;
@property (nonatomic, readonly, getter=isReduceble) BOOL isReduceble;
@property (nonatomic, copy) Expression* lastExpression;
@property (nonatomic, readonly) NSMutableDictionary* statements;
- (RootNode*) reduceWithApproximation: (BOOL) isApproximate;
- (NSString*) toString;
@end


@interface BrokenExpression: Expression{}
// + (BrokenExpression*) newWithStr: (NSString*) str;
@end

@interface Number: Expression{
    double _num;
}
    //may change double to float than. newWithFloatingPointNumber
    - (Number*) initWithFloat: (double) n;
@end

@interface PI: Number{
    BOOL _isApproximate;
}    
    - (PI*) init;
@end

@interface EXP: Number{
    BOOL _isApproximate;
}    
    - (EXP*) init;
@end

@interface Variable: Expression{
    NSString* _name;
    Expression* _expr;
}
    - (Variable*)initWithName: (NSString*) name andRoot: (RootNode*)rootNode;
@end

@interface UnaryFunction: Expression{
    Expression *_expr;
}
    - (UnaryFunction*) initWithArgument: (Expression*)arg;
    + (double) applyForArg: (double)arg;
@end

@interface BinaryFunction: Expression{
    Expression *_left, *_right;
}
- (BinaryFunction*) initWithLeftArgument: (Expression*) left rightArgument:(Expression*) right;
+ (double) applyForLeft: (double)left right: (double)right;
+ (NSString*) strFunction;
@end

@interface BinaryOperator: Expression{}
@end


@interface Negation: UnaryFunction{}
@end

@interface Addition: BinaryOperator{}
@end

@interface Substraction: BinaryOperator{}
@end

@interface Multiplication: BinaryOperator{}
@end

@interface Division: BinaryOperator{}
@end

//**
@interface Involution: BinaryOperator{}
@end

@interface IntegerDivision: BinaryOperator{}
@end

//mm just modulo?
@interface Modulation: BinaryOperator{}
@end

@interface Sin: UnaryFunction{}
@end

@interface Cos: UnaryFunction{}
@end

@interface Tg: UnaryFunction{}
@end

@interface Ctg: UnaryFunction{}
@end

@interface Abs: UnaryFunction{}
@end

@interface Sqrt: UnaryFunction{}
@end

@interface Min: BinaryFunction{}
@end

@interface Max: BinaryFunction{}
@end
//TODO: 
//    T_PI,
//    T_EXP,