//
//  SPOpenAPIResult.m
//  SpotlightSIMBL
//
//  Created by Nate Parrott on 11/2/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SPOpenAPIResult.h"
#import "MARTNSObject.h"
#import "RTMethod.h"
#import "SPQuery.h"
#import "SPResult.h"
#import "SPResponse.h"
#import "SPDictionaryResult.h"
#import "MethodOverride.h"
#import "SPPreviewController.h"
#import <WebKit/WebKit.h>
#import "_Flashlight_Bootstrap.h"
#import <FlashlightKit/FlashlightKit.h>

id __SS_SSOpenAPIResult_initWithQuery_result(SPResult *self, SEL cmd, NSString *query, FlashlightResult *result) {
    Class superclass = NSClassFromString(@"SPResult") ? : NSClassFromString(@"PRSResult");
    void (*superIMP)(id, SEL, NSString*, NSString*) = (void *)[superclass instanceMethodForSelector: @selector(initWithContentType:displayName:)];
    static NSInteger i = 0;
    NSString *contentType = [NSString stringWithFormat:@"%li", i++]; // cycle the contentType to prevent the system from dropping new results that have an unchanged title
    superIMP(self, cmd, contentType, result.title); // TODO: what does contentType actually do? it probably isn't a mime type
    self.title = result.title;
    objc_setAssociatedObject(self, @selector(resultAssociatedObject), result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

id __SS_SSOpenAPIResult_category(SPResult *self, SEL cmd) {
    return @"MENU_EXPRESSION";
}

SPPreviewController* __SS_SSOpenAPIResult_customPreviewController(SPResult *self, SEL cmd) {
    SPPreviewController *vc = objc_getAssociatedObject(self, @selector(customPreviewController));
    if (vc) {
        return vc;
    } else {
        Class cls = NSClassFromString(@"SPPreviewController") ? : NSClassFromString(@"PRSPreviewController");
        vc = [[cls alloc] initWithNibName:@"SPOpenAPIPreviewViewController" bundle:[NSBundle bundleWithIdentifier:@"com.nateparrott.SpotlightSIMBL"]];
        FlashlightResultView *resultView = (id)[(id)vc view];
        FlashlightResult *result = objc_getAssociatedObject(self, @selector(resultAssociatedObject));
        resultView.result = result;
        if (!_Flashlight_Is_10_10_2_Spotlight()) {
            vc.internalPreviewResult = self;
        }
        objc_setAssociatedObject(self, @selector(customPreviewController), vc, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return vc;
    }
}

unsigned long long __SS_SSOpenAPIResult_rank(SPResult *self, SEL cmd) {
    FlashlightResult *result = objc_getAssociatedObject(self, @selector(resultAssociatedObject));
    if ([result.json[@"dont_force_top_hit"] boolValue]) {
        return 1;
    } else {
        return 0xffffffffffffffff; // for top hit
    }
}

BOOL __SS_SSOpenAPIResult_shouldNotBeTopHit(SPResult *self, SEL cmd) {
    FlashlightResult *result = objc_getAssociatedObject(self, @selector(resultAssociatedObject));
    return [result.json[@"dont_force_top_hit"] boolValue];
}

id __SS_SSOpenAPIResult_iconImage(SPResult *self, SEL cmd) {
    FlashlightResult *result = objc_getAssociatedObject(self, @selector(resultAssociatedObject));
    NSString *iconPath = [result.pluginPath stringByAppendingPathComponent:@"icon.png"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconPath]) {
        NSData *infoJsonData = [NSData dataWithContentsOfFile:[result.pluginPath stringByAppendingPathComponent:@"info.json"]];
        if (infoJsonData) {
            NSDictionary *info = [NSJSONSerialization JSONObjectWithData:infoJsonData options:0 error:nil];
            if (info[@"iconPath"]) {
                iconPath = info[@"iconPath"];
            }
        }
    }
    return [[NSImage alloc] initByReferencingFile:iconPath];
}

// - (BOOL)openWithSearchString:(id)arg1 block:(CDUnknownBlockType)arg2;
BOOL __SS_SSOpenWithSearchString_block(SPResult *self, SEL cmd, NSString *searchString, void (^block)()) {
    FlashlightResult *result = objc_getAssociatedObject(self, @selector(resultAssociatedObject));
    
    SPPreviewController *previewVC = __SS_SSOpenAPIResult_customPreviewController(self, @selector(customPreviewController));
    FlashlightResultView *resultsView = (id)previewVC.view;
    
    return [result pressEnter:resultsView errorCallback:^(NSString *error) {
        
    }];
}

Class __SS_SPOpenAPIResultClass() {
    Class c = NSClassFromString(@"SPOpenAPIResult");
    if (c) return c;
    Class superclass = NSClassFromString(@"SPResult") ? : NSClassFromString(@"PRSResult");
    c = [superclass rt_createSubclassNamed:@"SPOpenAPIResult"];
    __SS_Override(c, NSSelectorFromString(@"initWithQuery:result:"), __SS_SSOpenAPIResult_initWithQuery_result);
    __SS_Override(c, NSSelectorFromString(@"category"), __SS_SSOpenAPIResult_category);
    __SS_Override(c, NSSelectorFromString(@"rank"), __SS_SSOpenAPIResult_rank);
    if (_Flashlight_Is_10_10_2_Spotlight()) {
        __SS_Override(c, NSSelectorFromString(@"sharedCustomPreviewController"), __SS_SSOpenAPIResult_customPreviewController);
    } else {
        __SS_Override(c, NSSelectorFromString(@"customPreviewController"), __SS_SSOpenAPIResult_customPreviewController);
    }
    __SS_Override(c, NSSelectorFromString(@"iconImage"), __SS_SSOpenAPIResult_iconImage);
    __SS_Override(c, NSSelectorFromString(@"iconImageForApplication"), __SS_SSOpenAPIResult_iconImage);
    __SS_Override(c, NSSelectorFromString(@"openWithSearchString:block:"), __SS_SSOpenWithSearchString_block);
    __SS_Override(c, NSSelectorFromString(@"shouldNotBeTopHit"), __SS_SSOpenAPIResult_shouldNotBeTopHit);
    return c;
}
