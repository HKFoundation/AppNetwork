# AppNetwork

    目前文件下载的问题
    1.下载过程中，直接删除下载文件，有可能会有残留
    2.退出到后台时会中断下载，再次返回前台没有做处理
    3.当软件首次安装时，会询问网络权限，如果此时有下载链接处理则会失败
    
    使用时需要注意点
    1.AppURL可以在实际应用中直接编辑，注意在更新 pods 时不要做 update 操作，防止替换已修改的文件
    如果需要更新，最好先把修改过的文件做备份
    
    git指令
    git add -A && git commit -m ""
    git push origin master
    git tag 0.0.7
    git push origin 0.0.7
    
    项目地址
    pod 'AppNetwork', :git => 'https://github.com/HKFoundation/AppNetwork.git'
