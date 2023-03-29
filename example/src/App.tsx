import * as React from 'react';

import { StyleSheet, View, Text, Button, NativeModules } from 'react-native';

export default function App() {

  return (
    <View style={styles.container}>
      <Button
        color={'#ff0000'}
        title="Click This"
        onPress={() => {
          NativeModules.PreviewVideo.showPreviewVideo({
            url: ""
          }).then((url: string) => {
            console.log(url)
          })
        }}
      ></Button>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
