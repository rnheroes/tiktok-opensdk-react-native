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

interface ShareSuccessResult {
  isSuccess: true;
}

interface ShareErrorResult {
  isSuccess: false;
  errorCode: number;
  subErrorCode: number;
  errorMsg: string;
}

type ShareResult = ShareSuccessResult | ShareErrorResult;

interface TikTokOpenSDKType {
  share: (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ) => Promise<ShareResult>;
}

const TikTokOpenSDK: TikTokOpenSDKType = {
  share: async (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ): Promise<ShareResult> => {
    try {
      if (Platform.OS === 'android') {
        const result = await TiktokOpensdkReactNative.share(
          clientKey,
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
          clientKey,
          mediaUrls,
          isImage,
          isGreenScreen
        );
        return result;
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
