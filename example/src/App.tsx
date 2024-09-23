import TikTokOpenSDK from 'tiktok-opensdk-react-native';

TikTokOpenSDK.login('your-client-key', 'your-redirect-uri')
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });
