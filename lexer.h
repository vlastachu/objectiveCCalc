
#import <objc/Object.h>
#import <Foundation/Foundation.h>
typedef enum Token : NSUInteger{
    T_Number,
    T_Identifier,
    T_EOF,
    T_Newline,
    T_LParen,
    T_RParen,
    T_Comma,
    T_Assignment,
    
    T_Plus,
    T_Minus,
    T_Asterisk,
    T_DblAsterisk,
    T_Slash,
    T_Backslash,
    T_Percent,

    T_PI,
    T_EXP,

    T_Sin,
    T_Cos,
    T_Tg,
    T_Ctg,
    T_Min,
    T_Max,
    T_Abs,
    T_Sqrt
} Token;

@interface Lexeme : NSObject{
    Token _token;
    NSString* _string;
    int _line;
    int _position;
    //for log:
    NSString *_source;
}
- initWithToken: (Token)token string: (NSString*) str source: (NSString*) source
    line: (int)line andPosition: (int)pos;
@property (nonatomic, readonly) Token token;
@property (nonatomic, readonly) NSString* string;
@property (nonatomic, readonly) int line;
@property (nonatomic, readonly) int position;
- (void)logAtLexeme;
- (void)logAtLexemeTo: (Lexeme*) endlex;
@end

@interface Lexer : NSObject{
    NSString *_source;
    char *_sourceBuf;
    int _cursor;
    int _prevCharPos;
    int _curLine;
}
//@property unsigned int curLine;
//char before and after current token
//@property unsigned int prevCharPos;
//@property unsigned int curCharPos; 
- (id) initWithFileContent: (NSString *) file; 
- (Lexeme*) getNextToken;
- (void) dealloc;
@end


//Before it was dictionary with tokens as key and their string representation as value.
//but keys should be objects. So there is many boxing/unboxing problems.
//Used for describe unfound tokens. Also in many cases string is pattern for recognize token. 
NSArray *tokenStringDict = [NSArray arrayWithObjects:
    @"number",      //T_Number
    @"identifier",  //T_Identifier
    @"end of file", //T_EOF
    @"end of line", //T_Newline
    @"(",           //T_LParen
    @")",           //T_RParen
    @",",           //T_Comma
    @"=",           //T_Assignment
    @"+",           //T_Plus
    @"-",           //T_Minus
    @"*",           //T_Asterisk
    @"**",          //T_DblAsterisk
    @"/",           //T_Slash
    @"\\",          //T_Backslash
    @"%",           //T_Percent
    @"pi",          //T_PI
    @"exp",         //T_EXP
    @"sin",         //T_Sin
    @"cos",         //T_Cos
    @"tg",          //T_Tg
    @"ctg",         //T_Ctg
    @"min",         //T_Min
    @"max",         //T_Max
    @"abs",         //T_Abs
    @"sqrt"         //T_Sqrt
    ];

//array of tokens which pattern matches with identifier pattern
NSArray *keywords = [NSArray arrayWithObjects:
    @T_PI, @T_EXP, @T_Sin, @T_Cos, @T_Tg, @T_Ctg, @T_Min, 
    @T_Max, @T_Abs, @T_Sqrt];
