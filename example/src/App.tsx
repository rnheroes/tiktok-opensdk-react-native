import TikTokSDK from 'tiktok-opensdk-react-native';

TikTokSDK.login('your-client-key', 'your-redirect-uri')
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });
