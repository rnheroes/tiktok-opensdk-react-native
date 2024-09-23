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

declare const TikTokSDK: TikTokSDKType;

export default TikTokSDK;
