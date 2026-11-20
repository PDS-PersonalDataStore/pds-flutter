{
  pkgs ? import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
  },
}:
with pkgs;
mkShell {
  ANDROID_SDK_ROOT = "/home/tau2c/Android/Sdk";
  packages = [
    jdk17
    android-tools
    flutter
    gh
    git
  ];
}
