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

interface ShareResult {
  isSuccess: boolean;
  errorCode: number;
  errorMsg: string;
}

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
        return result;
      } else if (Platform.OS === 'ios') {
        throw new Error('iOS implementation not available yet');
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
