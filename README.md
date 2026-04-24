# PeltierControl
Processing program for the peltier controller manufactured by Krag Electronics 

## PeltierControl.pde
クラッグ電子 https://kurag.o.oo7.jp/kurag-el/ 社製ペルチェコントローラ使用してPCから温度制御するクラス。
ProcessingのプログラムだがJavaへの修正は容易。
ProcessingでマルチウィンドウとするためにPAppletをextendsしている。

## PeltierControlTest.pde
温度制御のサンプルプログラム。キー操作で温度を上げ下げする。

## Dodge.pde
温度制御のサンプルプログラム。玉避けゲーム。
ゲームコントローラとProcessingの外部ライブラリGame Control Plusが必要。
なお、Game Control PlusはインテルCPUでないと動かない模様。

## Logger.pde
ログをファイルに書き出すためのクラス。
