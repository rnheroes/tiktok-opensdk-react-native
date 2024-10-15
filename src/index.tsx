import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'tiktok-opensdk-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const TiktokOpensdkReactNative = NativeModules.TiktokOpensdkReactNative
  ? NativeModules.TiktokOpensdkReactNative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

type ShareSuccessResult = {
  isSuccess: true;
};

type ShareErrorResult = {
  isSuccess: false;
  errorCode: number;
  subErrorCode?: number;
  shareState?: number;
  errorMsg: string;
};

type ShareResult = ShareSuccessResult | ShareErrorResult;

const TikTokOpenSDK = {
  share: async (
    mediaUrls: string[],
    isImage = false,
    isGreenScreen = false
  ): Promise<ShareResult> => {
    try {
      if (Platform.OS === 'android') {
        const result = await TiktokOpensdkReactNative.share(
          mediaUrls,
          isImage,
          isGreenScreen
        );
        if (result.isSuccess) {
          return { isSuccess: true };
        } else {
          return {
            isSuccess: false,
            errorCode: result.errorCode,
            subErrorCode: result.subErrorCode,
            errorMsg: result.errorMsg,
          };
        }
      } else if (Platform.OS === 'ios') {
        const result = await TiktokOpensdkReactNative.share(
          mediaUrls,
          isImage,
          isGreenScreen
        );
        if (result.isSuccess) {
          return { isSuccess: true };
        } else {
          return {
            isSuccess: false,
            errorCode: result.errorCode,
            shareState: result.shareState,
            errorMsg: result.errorMsg,
          };
        }
      } else {
        throw new Error('Unsupported platform');
      }
    } catch (error) {
      console.error('Error sharing to TikTok:', error);
      throw error;
    }
  },
};

export default TikTokOpenSDK;
