/*
 * That file used to parse command line arguments.
 * Then redirest given input to parser, execute by calculator and prints to
 * given output.
 */
#import "parser.h"
#import "AST.h"
#import <objc/Object.h>
#import <Foundation/Foundation.h>
#include <stdio.h>
//looks nice
#define not !

//puts argument string to stdout
//return 0 as flag of success (there is no other flags now)
int writeToSTDOUT(NSString *str){
    printf("%s", [str cStringUsingEncoding:NSUTF8StringEncoding]);
    return 0;
}

int readFromSTDIN(NSString** ptrInput){
    char buffer[1024]; 
    NSMutableString *strBuilder = [NSMutableString new];
    while(scanf("%1023s", buffer))
        [strBuilder appendString: [NSString stringWithUTF8String: buffer]];
    *ptrInput = [NSString stringWithString: strBuilder];
    [strBuilder release];
    return 0;
}

int main(int argc, char const *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL approximate = NO;
    NSString *input = nil;
    NSString *outputFilePath = nil;
    
    //check program arguments
    //we don't need first argument
    for (int i = 1; i < argc; ++i)
    {
        if (strcmp(argv[i], "-i") || strcmp(argv[i], "--input"))
        {
            if(++i != argc && argv[i][0] != '-'){
                NSString *inputFilePath = [NSString stringWithUTF8String: argv[i]];
                NSError *readError = nil;
                input = [NSString stringWithContentsOfFile: inputFilePath 
                                                  encoding: NSUTF8StringEncoding 
                                                     error: &readError];
                if(readError){
                    NSLog(@"error while trying read input: %@", readError);
                    return 1;
                }
                [inputFilePath release];
            }
            else{
                NSLog(@"expected file path after -i flag");
                return 1;
            }
            continue;
        }
        if (strcmp(argv[i], "-o") || strcmp(argv[i], "--output"))
        {
            if(++i != argc && argv[i][0] != '-'){
                outputFilePath = [NSString stringWithUTF8String: argv[i]];
                //TODO check directory existence and access rights would be nice
            }
            else{
                NSLog(@"expected file path after -o flag");
                return 1;
            }
            continue;
        }
        if (strcmp(argv[i], "-h") || strcmp(argv[i], "--help"))
        {
            printf("USAGE: calculator\n"
                   "program reads input, parse it, calculates expressions"
                   " with variables and print it to output\n"
                   "optional arguments:\n"
                   "-i, --input FILE\tread input from FILE\n"
                   "-o, --output FILE\tredirect output to FILE\n"
                   "--approximate\tcalculate to approximate float. By default calculator leaves "
                   "not irreducible expressions and PI, E in output\n"
                   "-h, --help\tthat text.");
            return 0;
        }
        if (strcmp(argv[i], "--approximate"))
        {
            approximate = YES;
            continue;
        }
    }
    if(not input)
        readFromSTDIN(&input);


    NSString *output = nil;
    NSError *writeError = nil;
    //TODO: get output
    Parser* parser = [[Parser alloc] initWithString: input];
    RootNode* root = [parser compileAST];
    [root reduceWithApproximation: approximate];
    output = [root toString];
    if(outputFilePath)
        [output writeToFile: outputFilePath  atomically: YES 
            encoding: NSUTF8StringEncoding error: &writeError];
    else
        writeToSTDOUT(output);
    if (writeError){
        NSLog(@"error while trying write to given output path: %@", writeError);
        return 1;
    }
    [pool drain];
    return 0;
}