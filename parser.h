#import "AST.h"
#import <objc/Object.h>
#import <Foundation/Foundation.h>

@interface Parser : NSObject{
    NSString* _source;
    NSMutableArray* _lexems;
    RootNode* _root;
}
- (Parser*)initWithString: (NSString*) source;
- (RootNode*)compileAST;
@end
