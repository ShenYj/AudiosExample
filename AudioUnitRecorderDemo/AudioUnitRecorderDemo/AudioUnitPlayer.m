//
//  AudioUnitPlayer.m
//  AudioUnitRecorderDemo
//
//  Created by EZen on 2024/12/09.
//

#import "AudioUnitPlayer.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

static const float kAudioRecorderSampleRate = 16000;

@interface AudioUnitPlayer () {
    AudioUnit _audioUnit;
    BOOL _isPlaying;
    NSMutableData *_audioDataBuffer;
    AudioStreamBasicDescription _audioFormat;
    UInt32 _currentPacketIndex;
}

@end

@implementation AudioUnitPlayer

- (instancetype)init {
    self = [super init];
    if (self) {
        _audioDataBuffer = [NSMutableData data];
        _isPlaying = NO;
        _currentPacketIndex = 0;
        [self setupAudioUnit];
    }
    return self;
}

// 初始化音频单元及相关设置
- (void)setupAudioUnit {
    AudioComponentDescription audioComponentDescription;
    audioComponentDescription.componentType = kAudioUnitType_Output;
    audioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioComponentDescription.componentFlags = 0;
    audioComponentDescription.componentFlagsMask = 0;

    AudioComponent audioComponent = AudioComponentFindNext(NULL, &audioComponentDescription);
    if (!audioComponent) {
        NSLog(@"Could not find audio component");
        return;
    }

    OSStatus status = AudioComponentInstanceNew(audioComponent, &_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error creating audio unit instance: %d", (int)status);
        return;
    }

    _audioFormat.mSampleRate        = kAudioRecorderSampleRate;
    _audioFormat.mFormatID          = kAudioFormatLinearPCM;
    _audioFormat.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _audioFormat.mFramesPerPacket   = 1;
    _audioFormat.mChannelsPerFrame  = 1;
    _audioFormat.mBitsPerChannel    = 16;
    _audioFormat.mBytesPerFrame     = 2;
    _audioFormat.mBytesPerPacket    = 2;
    _audioFormat.mReserved          = 0;

    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &_audioFormat,
                                  sizeof(_audioFormat));
    if (status!= noErr) {
        NSLog(@"Error setting audio unit stream format: %d", (int)status);
    }

    // 初始化均衡器单元（用于设置频段增益）
    AudioComponentDescription eqComponentDescription;
    eqComponentDescription.componentType = kAudioUnitType_Effect;
    eqComponentDescription.componentSubType = kAudioUnitSubType_ParametricEQ;
    eqComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    eqComponentDescription.componentFlags = 0;
    eqComponentDescription.componentFlagsMask = 0;
    AudioComponent eqComponent = AudioComponentFindNext(NULL, &eqComponentDescription);
    if (!eqComponent) {
        NSLog(@"Could not find equalizer component");
        return;
    }
    AudioUnit _equalizerUnit;
    status = AudioComponentInstanceNew(eqComponent, &_equalizerUnit);
    if (status!= noErr) {
        NSLog(@"Error creating equalizer unit instance: %d", (int)status);
        return;
    }
    status = AudioUnitInitialize(_equalizerUnit);
    if (status!= noErr) {
        NSLog(@"Error initializing equalizer unit: %d", (int)status);
        return;
    }
    
    // callback
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(_audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,
                         &playCallback,
                         sizeof(playCallback));
    
    
    status = AudioUnitInitialize(_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error initializing audio unit: %d", (int)status);
    }
    
}

// 播放功能
- (void)play {
    
    [self prepareAudioSession];
    
    if (!_audioUnit) {
        NSLog(@"AudioUnit not initialized");
        return;
    }
    _isPlaying = YES;
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error starting audio unit: %d", (int)status);
        return;
    }
}

// 暂停功能
- (void)pause {
    if (!_audioUnit) {
        NSLog(@"AudioUnit not initialized");
        return;
    }
    _isPlaying = NO;
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error stopping audio unit: %d", (int)status);
    }
}

// 继续播放功能
- (void)resume {
    if (!_audioUnit) {
        NSLog(@"AudioUnit not initialized");
        return;
    }
    _isPlaying = YES;
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error starting audio unit: %d", (int)status);
    }
}

// 停止功能
- (void)stop {
    if (!_audioUnit) {
        NSLog(@"AudioUnit not initialized");
        return;
    }
    _isPlaying = NO;
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    if (status!= noErr) {
        NSLog(@"Error stopping audio unit: %d", (int)status);
    }
    [_audioDataBuffer setData: nil];
    _currentPacketIndex = 0;
    
}

// 接收实时音频数据片段并添加到缓存
- (void)appendAudioData:(NSData *)data {
    
    [_audioDataBuffer appendData:data];
}


static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    
    AudioUnitPlayer *player = (__bridge AudioUnitPlayer *)inRefCon;
    UInt32 buffLen = ioData->mBuffers[0].mDataByteSize;
    
    NSLog(@"PlayCallback.length-----------------> mDataByteSize: %d, %ld",buffLen,(unsigned long)player->_audioDataBuffer.length);
    
    if (player->_audioDataBuffer.length >= buffLen) {
        NSData *data = [player->_audioDataBuffer subdataWithRange: NSMakeRange(0, buffLen)];
        AudioBuffer inBuffer = ioData->mBuffers[0];
        memcpy(inBuffer.mData, data.bytes, data.length);
        inBuffer.mDataByteSize = (UInt32)data.length;
        [player->_audioDataBuffer replaceBytesInRange: NSMakeRange(0, buffLen) withBytes: NULL length: 0];
    }
    else {
        NSLog(@"=====================静音:%ld",(unsigned long)player->_audioDataBuffer.length);
        
        for (UInt32 i=0; i < ioData->mNumberBuffers; i++)
        {
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
        }
    }
    return noErr;
}


#pragma mark -

- (BOOL)isPlaying {
    return _isPlaying;
}

- (void)prepareAudioSession {
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory: AVAudioSessionCategoryPlayAndRecord
                  withOptions: AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDefaultToSpeaker
                        error: &error];
    [audioSession setPreferredSampleRate: kAudioRecorderSampleRate error: &error];
    [audioSession setPreferredInputNumberOfChannels: 1 error: &error];
    [audioSession setPreferredIOBufferDuration: 1.0 error: &error];
    
    [audioSession setActive: YES error: &error];
}

@end
