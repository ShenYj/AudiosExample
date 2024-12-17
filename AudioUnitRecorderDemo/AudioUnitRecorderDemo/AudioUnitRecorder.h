//
//  AudioUnitRecorder.h
//  AudioUnitRecorderDemo
//
//  Created by EZen on 2024/12/02.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

extern const float EGAAudioRecorderSampleRate;
extern const AudioFileTypeID EGAAudioRecorderFileType;
extern const NSString * EGAAudioFileExtension;

@protocol EGAAudioRecorderDelegate;
@interface AudioUnitRecorder : NSObject

//properties
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, readonly, getter=isReadyToRecord) BOOL readyToRecord;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) float peakAudioLevel;
@property (nonatomic, weak, nullable) id<EGAAudioRecorderDelegate> delegate;

//initialization
- (id)initWithURL:(NSURL *)fileURL;

//basic recording
- (void)prepareToRecord;
- (void)record;
- (void)pause;
- (void)stop;
- (void)endRecording;

//audio file management
- (BOOL)deleteAudioFile:(NSError **)error;
- (BOOL)moveAudioFileToURL:(NSURL *)url error:(NSError **)error;

@end

@protocol EGAAudioRecorderDelegate <NSObject>

- (void)audioRecorderErrorOccurred:(AudioUnitRecorder *)recorder error:(NSError *)error;
/// 实时录音数据
/// - Parameters:
///   - recorder: 工具类自身
///   - data: 实时返回的 WAV格式数据
///   - level: -
///   - duration: 录音时长
- (void)audioRecorder:(AudioUnitRecorder *)recorder data:(NSData *)data didRecordAudioAtPeakAudioLevel:(float)level withUpdatedDuration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
