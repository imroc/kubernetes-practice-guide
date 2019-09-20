# kubectl 高效技巧

是否有过因为使用 kubectl 经常需要重复输入命名空间而苦恼？是否觉得应该要有个记住命名空间的功能，自动记住上次使用的命名空间，不需要每次都输入？可惜没有这种功能，但是，本文会教你一个非常巧妙的方法完美帮你解决这个痛点。

## k 命令

将如下脚本粘贴到当前shell\(注册k命令到当前终端session\):

```bash
function k() {
    cmdline=`HISTTIMEFORMAT="" history | awk '$2 == "kubectl" && (/-n/ || /--namespace/) {for(i=2;i<=NF;i++)printf("%s ",$i);print ""}' | tail -n 1`
    regs=('\-n [\w\-\d]+' '\-n=[\w\-\d]+' '\-\-namespace [\w\-\d]+' '\-\-namespace=[\w\-\d]+')
    for i in "${!regs[@]}"; do
        reg=${regs[i]}
        nsarg=`echo $cmdline | grep -o -P "$reg"`
        if [[ "$nsarg" == "" ]]; then
            continue
        fi
        cmd="kubectl $nsarg $@"
        echo "$cmd"
        $cmd
        return
    done
    cmd="kubectl $@"
    echo "$cmd"
    $cmd
}
```

mac 用户可以使用 dash 的 snippets 功能快速将上面的函数粘贴，使用 `kk.` 作为触发键 \(dash snippets可以全局监听键盘输入，使用指定的输入作为触发而展开配置的内容，相当于是全局代码片段\)，以后在某个终端想使用 `k` 的时候按下 `kk.` 就可以将 `k` 命令注册到当前终端，dash snippets 配置如图所示：

![kk](https://imroc.io/assets/blog/dash_kk.png)

将 `k` 当作 `kubectl` 来用，只是不需要输入命名空间，它会调用 kubectl 并自动加上上次使用的非默认的命名空间，如果想切换命名空间，再常规的使用一次 kubectl 就行，下面是示范：

![demo](https://imroc.io/assets/blog/k.gif)

哈哈，是否感觉可以少输入很多字符，提高 kubectl 使用效率了？这是目前我探索解决 kubectl 重复输入命名空间的最好方案，一开始是受 [fuck命令](https://github.com/nvbn/thefuck) 的启发，想用 go 语言开发个 k 命令，但是发现两个缺点：

* 需要安装二进制才可以使用（对于需要在多个地方用kubectl管理多个集群的人来说实在太麻烦）
* 如果当前 shell 默认没有将历史输入记录到 history 文件\( bash 的 history 文件默认是 `~/.bash_history`\)，那么将无法准确知道上一次 kubectl 使用的哪个命名空间

这里解释下第二个缺点的原因：ssh 连上服务器会启动一个 shell 进程，通常是 bash，大多 bash 默认配置会实时将历史输入追加到 `~/.bash_history`里，所以开多个ssh使用history命令看到的历史输入是一样的，但有些默认不会实时记录历史到`~/.bash_history`，而是记在当前 shell 进程的内存中，在 shell 退出时才会写入到文件。这种情况新起的进程是无法知道当前 shell 的最近历史输入的，[fuck命令](https://github.com/nvbn/thefuck) 也不例外。

所以最完美的解决方案就是注册函数到当前shell来调用，配合 dash 的 snippets 功能可以实现快速注册，解决复制粘贴的麻烦

