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

export interface LoginResult {
  authCode: string;
  grantedPermissions: string[];
  authError?: string;
  authErrorDescription?: string;
}

export interface ShareResult {
  isSuccess: boolean;
  errorCode: number;
  subErrorCode: number;
  errorMsg: string;
}

export interface TikTokSDKType {
  login: (clientKey: string, redirectUri: string) => Promise<LoginResult>;
  handleLoginResult: (
    intentUri: string,
    redirectUri: string
  ) => Promise<LoginResult>;
  share: (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ) => Promise<void>;
  handleShareResult: (intentUri: string) => Promise<ShareResult>;
  grantUriPermission: (uri: string) => Promise<void>;
}

const TikTokSDK: TikTokSDKType = {
  login: (clientKey: string, redirectUri: string): Promise<LoginResult> => {
    return TiktokOpensdkReactNative.login(clientKey, redirectUri);
  },

  handleLoginResult: (
    intentUri: string,
    redirectUri: string
  ): Promise<LoginResult> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.handleLoginResult(intentUri, redirectUri);
    }
    return Promise.reject('Not implemented for this platform');
  },

  share: (
    clientKey: string,
    mediaUrls: string[],
    isImage: boolean,
    isGreenScreen: boolean
  ): Promise<void> => {
    return TiktokOpensdkReactNative.share(
      clientKey,
      mediaUrls,
      isImage,
      isGreenScreen
    );
  },

  handleShareResult: (intentUri: string): Promise<ShareResult> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.handleShareResult(intentUri);
    }
    return Promise.reject('Not implemented for this platform');
  },

  grantUriPermission: (uri: string): Promise<void> => {
    if (Platform.OS === 'android') {
      return TiktokOpensdkReactNative.grantUriPermission(uri);
    }
    return Promise.reject('Not implemented for this platform');
  },
};

export default TikTokSDK;
