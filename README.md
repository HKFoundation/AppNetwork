# AppNetwork

    目前文件下载的问题
    1.下载过程中，直接退出程序则不保存已下载数据
    2.退出到后台时会中断下载，再次返回前台没有做处理
    3.当软件首次安装时，会询问网络权限，如果此时有下载链接处理则会失败
    
    使用时需要注意点
    1.AppURL可以在实际应用中直接编辑，注意在更新 pods 时不要做 update 操作，防止替换已修改的文件
    
    git指令
    git add -A && git commit -m ""
    git push origin master
    git tag 0.1.0
    git push origin 0.1.0
    
    项目地址
    pod 'AppNetwork', :git => 'https://github.com/HKFoundation/AppNetwork.git'
