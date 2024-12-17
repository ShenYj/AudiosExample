//
//  AudioUnitPlayer.h
//  AudioUnitRecorderDemo
//
//  Created by EZen on 2024/12/09.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioUnitPlayer : NSObject

@property (nonatomic, assign, readonly, getter=isPlaying) BOOL Playing;

- (void)play;
- (void)pause;
- (void)resume;
- (void)stop;

/// 接收实时音频数据片段并添加到缓存
- (void)appendAudioData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
