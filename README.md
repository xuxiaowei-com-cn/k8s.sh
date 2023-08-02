<div align="center" style="text-align: center;">
    <h1>k8s.sh</h1>
    <h3>Kubernetes（k8s）自动安装配置脚本</h3>
    <a target="_blank" href="https://github.com/996icu/996.ICU/blob/master/LICENSE">
        <img alt="License-Anti" src="https://img.shields.io/badge/License-Anti 996-blue.svg">
    </a>
    <a target="_blank" href="https://996.icu/#/zh_CN">
        <img alt="Link-996" src="https://img.shields.io/badge/Link-996.icu-red.svg">
    </a>
    <a target="_blank" href="https://qm.qq.com/cgi-bin/qm/qr?k=ZieC6s1WB4njfVbrDHYgoNS8YpT26VtF&jump_from=webapi">
        <img alt="QQ群" src="https://img.shields.io/badge/QQ群-696503132-blue.svg"/>
    </a>
</div>

<p></p>

<div align="center" style="text-align: center;">
    <a target="_blank" href="https://work.weixin.qq.com/gm/75cfc47d6a341047e4b6aca7389bdfa8">
        <img alt="企业微信群" src="static/wechat-work.jpg" height="100"/>
    </a>
</div>

<p></p>

<div align="center" style="text-align: center;">
  为简化开发工作、提高生产率、解决常见问题而生
</div>

<p></p>

<div align="center" style="text-align: center;">

  <a target="_blank" href="https://space.bilibili.com/198580655">
    <img alt="bilibili 粉丝" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.spencerwoo.com%2Fsubstats%2F%3Fsource%3Dbilibili%26queryKey%3D198580655&label=bilibili%20fans&query=%24.data.totalSubs&logo=bilibili">
  </a>

  <a target="_blank" href="https://blog.csdn.net/qq_32596527">
    <img alt="CSDN 码龄" src="https://img.shields.io/badge/dynamic/xml?color=orange&label=CSDN&query=%2F%2Fdiv%5B%40class%3D%27person-code-age%27%5D%5B1%5D%2Fspan%5B1%5D%2Ftext%28%29%5B1%5D&url=https%3A%2F%2Fblog.csdn.net%2Fqq_32596527&logo=data:image/x-icon;base64,AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAxVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zda/P9qhPz/mKr9/7bC/f/Fz/7/ydL+/8HM/v+tu/3/jaH9/156/P8zV/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/z9h/P+gsP3/8fP+/////////////////////////////////////////////////+ru/v+Zqv3/PV/8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9lgPz/6+/+///////////////////////////////////////////////////////////////////////s7/7/Y378/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aoT8//r6/v///////////////////////v7+/+Po/v/R2f7/y9T+/9rg/v/3+f7////////////////////////////j6P7/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Zm/P/w8/7/////////////////5+v+/4ab/f9AYvz/MVX8/zFV/P8xVfz/MVX8/zVY/P9kf/z/tsP9//39/v////////////T2/v8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/sL79/////////////////87W/v8/Yfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ZYD8//L0/v//////n7D9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Bh/P/6+/7////////////v8v7/QmP8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/TWz8/3GJ/P8yVvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/e5L8/////////////////5qr/f8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P+mtv3/////////////////XHn8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7/L/f////////////////87Xfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ydL+////////////+/v+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P/Ezv7////////////9/f7/M1b8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7G//f////////////////9HZ/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kqX9/////////////////22H/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9kf/z/////////////////pbX9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zRX/P/v8v7////////////s7/7/Nln8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/6Ky/f////////////////+Inf3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/RWb8//f4/v////////////H0/v9Kafz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/PV/8/1Jw/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kKT9/////////////////9vh/v9DZPz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1Fv/P/m6/7//v7+/3aO/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8zVvz/xM79/////////////////+fr/v9viPz/MVX8/zFV/P8xVfz/MVX8/zRX/P+Emf3/8/X+////////////xc/+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P87Xfz/ztf+///////////////////////i5/7/sL79/5+w/f+ywP3/6u3+//////////////////////+uvP3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P83Wvz/sL79//7+/v//////////////////////////////////////////////////////3OL+/0Vl/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aYP8/9Pb/v//////////////////////////////////////9fb+/5yu/f84W/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1d0/P+Spf3/t8T9/8fR/v/Dzv7/qrn9/3uS/P88Xvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=">
  </a>

  <a target="_blank" href="https://blog.csdn.net/qq_32596527">
    <img alt="CSDN 粉丝" src="https://img.shields.io/badge/dynamic/xml?color=orange&label=CSDN&prefix=%E7%B2%89%E4%B8%9D&query=%2F%2Fli%5B4%5D%2Fa%5B1%5D%2Fdiv%5B%40class%3D%27user-profile-statistics-num%27%5D%5B1%5D%2Ftext%28%29%5B1%5D&url=https%3A%2F%2Fblog.csdn.net%2Fqq_32596527&logo=data:image/x-icon;base64,AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAxVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zda/P9qhPz/mKr9/7bC/f/Fz/7/ydL+/8HM/v+tu/3/jaH9/156/P8zV/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/z9h/P+gsP3/8fP+/////////////////////////////////////////////////+ru/v+Zqv3/PV/8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9lgPz/6+/+///////////////////////////////////////////////////////////////////////s7/7/Y378/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aoT8//r6/v///////////////////////v7+/+Po/v/R2f7/y9T+/9rg/v/3+f7////////////////////////////j6P7/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Zm/P/w8/7/////////////////5+v+/4ab/f9AYvz/MVX8/zFV/P8xVfz/MVX8/zVY/P9kf/z/tsP9//39/v////////////T2/v8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/sL79/////////////////87W/v8/Yfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ZYD8//L0/v//////n7D9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Bh/P/6+/7////////////v8v7/QmP8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/TWz8/3GJ/P8yVvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/e5L8/////////////////5qr/f8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P+mtv3/////////////////XHn8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7/L/f////////////////87Xfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ydL+////////////+/v+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P/Ezv7////////////9/f7/M1b8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7G//f////////////////9HZ/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kqX9/////////////////22H/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9kf/z/////////////////pbX9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zRX/P/v8v7////////////s7/7/Nln8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/6Ky/f////////////////+Inf3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/RWb8//f4/v////////////H0/v9Kafz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/PV/8/1Jw/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kKT9/////////////////9vh/v9DZPz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1Fv/P/m6/7//v7+/3aO/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8zVvz/xM79/////////////////+fr/v9viPz/MVX8/zFV/P8xVfz/MVX8/zRX/P+Emf3/8/X+////////////xc/+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P87Xfz/ztf+///////////////////////i5/7/sL79/5+w/f+ywP3/6u3+//////////////////////+uvP3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P83Wvz/sL79//7+/v//////////////////////////////////////////////////////3OL+/0Vl/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aYP8/9Pb/v//////////////////////////////////////9fb+/5yu/f84W/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1d0/P+Spf3/t8T9/8fR/v/Dzv7/qrn9/3uS/P88Xvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=">
  </a>

  <a target="_blank" href="https://blog.csdn.net/qq_32596527">
    <img alt="CSDN 访问" src="https://img.shields.io/badge/dynamic/xml?color=orange&label=CSDN&prefix=%E8%AE%BF%E9%97%AE&query=//span[1]/div[@class='user-profile-statistics-num'][1]/text()[1]&url=https%3A%2F%2Fblog.csdn.net%2Fqq_32596527&logo=data:image/x-icon;base64,AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAxVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zda/P9qhPz/mKr9/7bC/f/Fz/7/ydL+/8HM/v+tu/3/jaH9/156/P8zV/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/z9h/P+gsP3/8fP+/////////////////////////////////////////////////+ru/v+Zqv3/PV/8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9lgPz/6+/+///////////////////////////////////////////////////////////////////////s7/7/Y378/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aoT8//r6/v///////////////////////v7+/+Po/v/R2f7/y9T+/9rg/v/3+f7////////////////////////////j6P7/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Zm/P/w8/7/////////////////5+v+/4ab/f9AYvz/MVX8/zFV/P8xVfz/MVX8/zVY/P9kf/z/tsP9//39/v////////////T2/v8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/sL79/////////////////87W/v8/Yfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ZYD8//L0/v//////n7D9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Bh/P/6+/7////////////v8v7/QmP8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/TWz8/3GJ/P8yVvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/e5L8/////////////////5qr/f8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P+mtv3/////////////////XHn8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7/L/f////////////////87Xfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ydL+////////////+/v+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P/Ezv7////////////9/f7/M1b8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7G//f////////////////9HZ/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kqX9/////////////////22H/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9kf/z/////////////////pbX9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zRX/P/v8v7////////////s7/7/Nln8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/6Ky/f////////////////+Inf3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/RWb8//f4/v////////////H0/v9Kafz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/PV/8/1Jw/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kKT9/////////////////9vh/v9DZPz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1Fv/P/m6/7//v7+/3aO/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8zVvz/xM79/////////////////+fr/v9viPz/MVX8/zFV/P8xVfz/MVX8/zRX/P+Emf3/8/X+////////////xc/+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P87Xfz/ztf+///////////////////////i5/7/sL79/5+w/f+ywP3/6u3+//////////////////////+uvP3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P83Wvz/sL79//7+/v//////////////////////////////////////////////////////3OL+/0Vl/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aYP8/9Pb/v//////////////////////////////////////9fb+/5yu/f84W/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1d0/P+Spf3/t8T9/8fR/v/Dzv7/qrn9/3uS/P88Xvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=">
  </a>

  <a target="_blank" href="https://blog.csdn.net/qq_32596527">
    <img alt="CSDN 博客" src="https://img.shields.io/badge/dynamic/json?color=orange&label=CSDN&prefix=%E5%8D%9A%E5%AE%A2&query=%24.data.blog&suffix=%E7%AF%87&url=https%3A%2F%2Fblog.csdn.net%2Fcommunity%2Fhome-api%2Fv1%2Fget-tab-total%3Fusername%3Dqq_32596527&logo=data:image/x-icon;base64,AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAxVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zda/P9qhPz/mKr9/7bC/f/Fz/7/ydL+/8HM/v+tu/3/jaH9/156/P8zV/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/z9h/P+gsP3/8fP+/////////////////////////////////////////////////+ru/v+Zqv3/PV/8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9lgPz/6+/+///////////////////////////////////////////////////////////////////////s7/7/Y378/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aoT8//r6/v///////////////////////v7+/+Po/v/R2f7/y9T+/9rg/v/3+f7////////////////////////////j6P7/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Zm/P/w8/7/////////////////5+v+/4ab/f9AYvz/MVX8/zFV/P8xVfz/MVX8/zVY/P9kf/z/tsP9//39/v////////////T2/v8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/sL79/////////////////87W/v8/Yfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ZYD8//L0/v//////n7D9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/0Bh/P/6+/7////////////v8v7/QmP8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/TWz8/3GJ/P8yVvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/e5L8/////////////////5qr/f8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P+mtv3/////////////////XHn8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7/L/f////////////////87Xfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/ydL+////////////+/v+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P/Ezv7////////////9/f7/M1b8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/7G//f////////////////9HZ/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kqX9/////////////////22H/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P9kf/z/////////////////pbX9/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zRX/P/v8v7////////////s7/7/Nln8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/6Ky/f////////////////+Inf3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/RWb8//f4/v////////////H0/v9Kafz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/PV/8/1Jw/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/kKT9/////////////////9vh/v9DZPz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1Fv/P/m6/7//v7+/3aO/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8zVvz/xM79/////////////////+fr/v9viPz/MVX8/zFV/P8xVfz/MVX8/zRX/P+Emf3/8/X+////////////xc/+/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P87Xfz/ztf+///////////////////////i5/7/sL79/5+w/f+ywP3/6u3+//////////////////////+uvP3/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P83Wvz/sL79//7+/v//////////////////////////////////////////////////////3OL+/0Vl/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/aYP8/9Pb/v//////////////////////////////////////9fb+/5yu/f84W/z/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/1d0/P+Spf3/t8T9/8fR/v/Dzv7/qrn9/3uS/P88Xvz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/MVX8/zFV/P8xVfz/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=">
  </a>

  <a target="_blank" href="https://www.jetbrains.com/idea">
    <img alt="IntelliJ IDEA" src="https://img.shields.io/static/v1?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAAAAAByaaZbAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfmBRkBICRBfW8eAAABPklEQVRIx+2UTStEYRiGr/kqZWaKMoyQUsoCWdn4AZKPlZSF5fgPVhYWStlZqPkB7GynWSg/QCmhUFOUGCPNZBrlnNtijmneOYZzykrn2p2e536f577P2wsBPvmQlACQg13Mr4b9CCTpuMunQIdGT8gQRCBZAQRPu0B6aRjsvqKXCRcAJO8lTTf3/GQJKF8Bz5481CfMvEnnxtrRduKhPET7R6GWka+UrBW//8Hej3haqZQFYgNz8VDmYbNNT8iSFDdMM1iSyh3uWHsAesNgVc1D7k4hMeISrN0uAOtAwTYF6Smg2UQUYDYbO8qdjS0Cua9CahsgPd8NleuW3WOFRiTV+nTj8mnL5XbixinVlnEJ7L1vkuzcuJT0ejDufL98UTjZmWyJsqFJvT9aBAT8J5zrrXYFF788xn8gCPDCJ2cr3I1zqSjOAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDIyLTA1LTI1VDAxOjMyOjM2KzAwOjAwH/0yeQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyMi0wNS0yNVQwMTozMjozNiswMDowMG6gisUAAAAASUVORK5CYII=&message=IntelliJ IDEA">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="GitHub stars" src="https://img.shields.io/github/stars/xuxiaowei-com-cn/k8s.sh?logo=github">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="GitHub forks" src="https://img.shields.io/github/forks/xuxiaowei-com-cn/k8s.sh?logo=github">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="GitHub watchers" src="https://img.shields.io/github/watchers/xuxiaowei-com-cn/k8s.sh?logo=github">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/xuxiaowei-com-cn/k8s.sh">
  </a>

  <a target="_blank" href="https://gitee.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="码云Gitee stars" src="https://gitee.com/xuxiaowei-com-cn/k8s.sh/badge/star.svg?theme=blue">
  </a>

  <a target="_blank" href="https://gitee.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="码云Gitee forks" src="https://gitee.com/xuxiaowei-com-cn/k8s.sh/badge/fork.svg?theme=blue">
  </a>

  <a target="_blank" href="https://gitlab.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="Gitlab stars" src="https://badgen.net/gitlab/stars/xuxiaowei-com-cn/k8s.sh?icon=gitlab">
  </a>

  <a target="_blank" href="https://gitlab.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="Gitlab forks" src="https://badgen.net/gitlab/forks/xuxiaowei-com-cn/k8s.sh?icon=gitlab">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="OSCS Status" src="https://www.oscs1024.com/platform/badge/xuxiaowei-com-cn/k8s.sh.svg?size=small">
  </a>

  <a target="_blank" href="https://github.com/xuxiaowei-com-cn/k8s.sh">
    <img alt="total lines" src="https://tokei.rs/b1/github/xuxiaowei-com-cn/k8s.sh">
  </a>

  <a target="_blank" href="https://www.apache.org/licenses/LICENSE-2.0">
    <img alt="code style" src="https://img.shields.io/badge/license-Apache 2-blue">
  </a>
</div>

<p></p>

1. 支持 CentOS 7/8、Anolis 7/8/23 系统主流版本，详情见：https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/issues/12
2. 支持 Ubuntu 系统主流版本，详情见：https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/issues/21
3. 一键支持 自定义 Kubernetes（k8s）、Calico 版本
4. 一键支持 单机集群
5. 一键支持 一主多从
6. 一键支持 高可用
7. 自动安装、配置 Docker、Containerd
8. 自动安装、配置 Kubernetes（k8s）
9. 自动安装、配置 Calico 网络插件
10. 自动安装、配置 kubectl 命令自动补充
11. 自动安装、配置 VIP（Virtual IP Address，虚拟 IP 地址）

## 环境变量说明

| 镜像参数                  | 说明                                                                   | 原始镜像                                                                                        | 加速镜像使用示例                                                                     | 作者个人镜像                                                                                                   |
|-----------------------|----------------------------------------------------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| calico-mirrors        | calico 网络组件加速镜像（注意此处有 s，控制多个镜像，不控制镜像名称、不控制版本号），自定义版本见 calico-version | 包含 docker.io/calico/cni、docker.io/calico/kube-controllers、docker.io/calico/kube-controllers | calico-mirrors=hub-mirror.c.163.com                                          | calico-mirrors=registry.jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud                                      |
| keepalived-mirror     | keepalived 镜像，只控制镜像名称、不控制版本号                                         | lettore/keepalived                                                                          | keepalived-mirror=hub-mirror.c.163.com/lettore/keepalived                    | keepalived-mirror=registry.jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud/lettore/keepalived                |
| haproxy-mirror        | haproxy 镜像，只控制镜像名称、不控制版本号                                            | haproxytech/haproxy-debian                                                                  | haproxy-mirror=hub-mirror.c.163.com/haproxytech/haproxy-debian               | haproxy-mirror=registry.jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud/haproxytech/haproxy-debian           |
| metrics-server-mirror | metrics-server 镜像，只控制镜像名称、不控制版本号，默认使用阿里云镜像                           | registry.k8s.io/metrics-server/metrics-server                                               | metrics-server-mirror=registry.aliyuncs.com/google_containers/metrics-server | metrics-server-mirror=registry.jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud/metrics-server/metrics-server |

| 安装/配置参数                         | 说明                                                                               | 默认值          | 使用示例                                                                                                                                                     |
|---------------------------------|----------------------------------------------------------------------------------|--------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| ntp-install-skip                | 跳过 NTP 安装                                                                        | false        | ntp-install-skip                                                                                                                                         |
| bash-completion-install-skip    | 跳过 bash-completion 安装                                                            | false        | bash-completion-install-skip                                                                                                                             |
| selinux-permissive-skip         | 跳过 关闭 selinux                                                                    | false        | selinux-permissive-skip                                                                                                                                  |
| firewalld-stop-skip             | 跳过 关闭 防火墙 firewalld                                                              | false        | firewalld-stop-skip                                                                                                                                      |
| swap-off-skip                   | 跳过 关闭 交换空间 swap                                                                  | false        | swap-off-skip                                                                                                                                            |
| docker-repo-skip                | 跳过 添加 docker 仓库                                                                  | false        | docker-repo-skip                                                                                                                                         |
| docker-ce-install-skip          | 跳过 docker-ce 安装                                                                  | false        | docker-ce-install-skip                                                                                                                                   |
| containerd-install-skip         | 跳过 containerd 安装                                                                 | false        | containerd-install-skip                                                                                                                                  |
| kubernetes-repo-skip            | 跳过 添加 kubernetes 仓库                                                              | false        | kubernetes-repo-skip                                                                                                                                     |
| kubernetes-conf-skip            | 跳过 kubernetes 配置                                                                 | false        | kubernetes-conf-skip                                                                                                                                     |
| kubernetes-install-skip         | 跳过 kubernetes 安装                                                                 | false        | kubernetes-install-skip                                                                                                                                  |
| kubernetes-init-skip            | 跳过 kubernetes 初始化                                                                | false        | kubernetes-init-skip                                                                                                                                     |
| kubernetes-taint                | 指定 kubernetes 全部去污                                                               | false        | kubernetes-taint                                                                                                                                         |
| kubernetes-version              | 指定 kubernetes 版本                                                                 | 最新版          | kubernetes-version=1.26.0                                                                                                                                |
| kubernetes-images-pull          | 拉取 kubernetes 镜像（在初始化前提前拉取）                                                      | false        | kubernetes-images-pull                                                                                                                                   |
| calico-init-skip                | 跳过 calico 初始化                                                                    | false        | calico-init-skip                                                                                                                                         |
| calico-version                  | 指定 calico 版本                                                                     | 3.2          | calico-version=3.25                                                                                                                                      |
| calico-manifests-mirror         | 自定义 calico 配置文件，优先级高于 calico-version                                             | 从 官网 中获取     | calico-manifests-mirror=https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/main/mirrors/projectcalico/calico/v3.25/manifests/calico.yaml                  |
| interface-name                  | 指定 网卡 名称                                                                         | 自动获取         | interface-name=ens33                                                                                                                                     |
| metrics-server-install          | 指定 Metrics Server 安装                                                             | false        | metrics-server-install                                                                                                                                   |
| metrics-server-version          | 指定 Metrics Server 版本                                                             | 0.6.3        | metrics-server-version=0.6.3                                                                                                                             |
| metrics-server-availability     | 指定 Metrics Server 使用高可用                                                          | false        | metrics-server-availability                                                                                                                              |
| metrics-server-manifests-mirror | 自定义 Metrics Server 配置文件，优先级高于 metrics-server-version、metrics-server-availability | 从 GitHub 中获取 | metrics-server-manifests-mirror=https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/main/mirrors/kubernetes-sigs/metrics-server/v0.6.3/components.yaml     |
| availability-vip-install        | 开启高可用 VIP 安装                                                                     | false        | availability-vip-install                                                                                                                                 |
| availability-vip                | 高可用 VIP 地址（Virtual IP Address，虚拟 IP 地址）                                          | 无            | availability-vip=192.168.80.100                                                                                                                          |
| availability-vip-no             | 高可用 VIP 编号，整数数字类型，其中 1 代表主，其余为备用，不可重复，创建 VIP 时必填，VIP 节点中必须存在一个 1                 | 无            | availability-vip-no=1                                                                                                                                    |
| availability-master             | 高可用 主节点配置，包含主节点名称（仅在VIP管理时使用）、主节点IP、主节点端口，创建 VIP 时必填，格式：名称@ip:端口，使用多次指定设置多个值     | 无            | availability-master=k8s-master1@192.168.80.81:6443 availability-master=k8s-master2@192.168.80.82:6443 availability-master=k8s-master3@192.168.80.83:6443 |

## 使用前说明

1. <strong><font color="red">请务必使用独立系统执行脚本。</font></strong>
2. <strong><font color="red">请务必使用独立系统执行脚本。</font></strong>
3. <strong><font color="red">请务必使用独立系统执行脚本。</font></strong>
4. k8s 各节点主机名唯一，不能存在相同的。推荐主节点使用 k8s-xx 或者 control-plane-xx，工作节点 node-xx
5. k8s 主机名：必须符合小写的 RFC 1123 子域，必须由小写字母数字字符“-”或“.”组成，并且必须以字母数字字符开头和结尾
6. 由于某些软件基于主机名才能正常运行，为了避免风险，脚本不支持修改主机名，请自行修改
7. 命令 hostname 为临时修改主机名，配置文件 /etc/hostname 为配置文件中的主机名，服务器重启后，会 hostname 配置的主机名会消失，恢复成
   /etc/hostname 中的主机名
8. 集群主节点初始化错误、集群工作节点加入集群错误，请使用 `kubeadm reset`
   重置节点的配置，并根据提示手动删除 `$HOME/.kube/config`、`/etc/cni/net.d` 文件（夹）等
9. 安装配置过程将关闭防火墙，推荐使用独立机器部署 k8s
10. 如果 k8s 宿主机有多个网卡，请自行指定网卡名称
11. 安装时，会卸载 `老版 Docker`（非 `旧版 Docker`），安装最新版 Docker、Containerd，修改 Docker、Containerd 配置文件，重启
    Docker、Containerd
    1. 卸载软件如下
        1. docker
        2. docker-client
        3. docker-client-latest
        4. docker-common
        5. docker-latest
        6. docker-latest-logrotate
        7. docker-logrotate
        8. docker-engine
    2. 安装软件如下
        1. docker-ce
        2. docker-ce-cli
        3. containerd.io
        4. docker-buildx-plugin
        5. docker-compose-plugin
    3. 修改配置如下
        1. /etc/docker/daemon.json
        2. /etc/containerd/config.toml

## 使用说明

1. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试）

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    ./k8s.sh kubernetes-taint
    ```

2. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），使用 k8s 指定版本

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    # 指定 k8s 版本号（版本号不带字母）
    # 在 GitHub 查看 k8s 发布的版本：https://github.com/kubernetes/kubernetes/tags
    # 在 GitCode 查看 k8s 发布的版本：https://gitcode.net/mirrors/kubernetes/kubernetes/-/tags
    ./k8s.sh kubernetes-taint kubernetes-version=1.26.0
    ```

3. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），不安装 docker-ce（k8s 使用 containerd）

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    ./k8s.sh kubernetes-taint docker-ce-install-skip
    ```

4. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），仅安装，不进行初始化

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令，仅安装，不进行初始化
    ./k8s.sh kubernetes-taint kubernetes-init-skip calico-init-skip
    ```

5. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），仅安装、拉取镜像，不进行初始化

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令，仅安装、拉取镜像，不进行初始化
    ./k8s.sh kubernetes-taint kubernetes-init-skip calico-init-skip kubernetes-images-pull
    ```

6. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），使用 calico 指定版本

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    # 指定 calico 版本号（版本号不带字母）
    # 查看 calico 发布的版本：https://docs.tigera.io/archive/
    ./k8s.sh kubernetes-taint calico-version=3.25
    ```

7. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），使用 calico 网络组件的加速镜像

    ```shell
    # calico 网络组件：使用网易云 calico-mirrors=hub-mirror.c.163.com
    # 如果自己有镜像，也可使用自己的镜像
    # 作者个人镜像仓库：calico-mirrors=registry.jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud
    
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    ./k8s.sh kubernetes-taint calico-mirrors=hub-mirror.c.163.com
    ```

8. k8s 单节点安装（只有一个主节点，无高可用，仅用于学习、测试），安装 Metrics Server 插件

    ```shell
    # 下载脚本，下载后的文件名为 k8s.sh
    curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
    # 授权
    chmod +x k8s.sh
    # 执行安装命令
    ./k8s.sh kubernetes-taint metrics-server-install
    
    # 执行安装命令：自定义版本
    # ./k8s.sh kubernetes-taint metrics-server-install metrics-server-version=0.6.2
    
    # 执行安装命令：使用高可用
    # ./k8s.sh kubernetes-taint metrics-server-install metrics-server-availability
    
    # 执行安装命令：自定义版本、使用高可用
    # ./k8s.sh kubernetes-taint metrics-server-install metrics-server-version=0.6.2 metrics-server-availability
    
    # 执行安装命令：自定义下载配置文件（优先级高于 metrics-server-version、metrics-server-availability，可指定高可用）
    # ./k8s.sh kubernetes-taint metrics-server-install metrics-server-manifests-mirror=https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/main/mirrors/kubernetes-sigs/metrics-server/v0.6.3/components.yaml
    ```

9. k8s 集群（一主多从，无高可用，仅用于学习、测试）

    1. 主节点：安装软件、初始化集群

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        # 执行安装命令
        ./k8s.sh
        
        
        # 暂存初始化完成后控制台打印的工作节点加入集群的命令，例如：
        # kubeadm join 192.168.61.147:6443 --token ykrnfh.i4qwth17fopc0gtx \
        # --discovery-token-ca-cert-hash sha256:9e81fa0b04a57517feb1c9e34edc0aa6563b64db54887fc072a08d7d1235861d
        
        
        # 也可使用命令在主节点生成工作节点加入集群的命令：kubeadm token create --print-join-command
        
        
        ```

    2. 工作节点：安装软件、加入集群

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        # 执行安装命令，仅安装、拉取镜像，不进行初始化
        ./k8s.sh kubernetes-init-skip calico-init-skip
        
        
        # 执行在主节点得到的工作加入集群的命令，例如：
        # kubeadm join 192.168.61.147:6443 --token ykrnfh.i4qwth17fopc0gtx --discovery-token-ca-cert-hash sha256:9e81fa0b04a57517feb1c9e34edc0aa6563b64db54887fc072a08d7d1235861d
        
        # 可使用 kubeadm token create --print-join-command 创建工作节点加入集群的命令
        
        ```

10. k8s 集群（三主多从，高可用，生产就绪）

    1. VIP（Virtual IP Address，虚拟 IP 地址）

       VIP 至少需要部署**3**台机器，可与主节点使用相同的机器

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        
        # 第 1 个 VIP 宿主机：执行安装命令（与其他 VIP 命令中的 availability-vip-no 不同，必须存在一个值为 1）
        ./k8s.sh availability-vip-install \
          availability-vip=192.168.80.100 \
          interface-name=ens33 \
          availability-master=k8s-master1@192.168.80.81:6443 \
          availability-master=k8s-master2@192.168.80.82:6443 \
          availability-master=k8s-master3@192.168.80.83:6443 \
          availability-vip-no=1
        
        # 第 2 个 VIP 宿主机：执行安装命令（与其他 VIP 命令中的 availability-vip-no 不同，必须存在一个值为 1）
        ./k8s.sh availability-vip-install \
          availability-vip=192.168.80.100 \
          interface-name=ens33 \
          availability-master=k8s-master1@192.168.80.81:6443 \
          availability-master=k8s-master2@192.168.80.82:6443 \
          availability-master=k8s-master3@192.168.80.83:6443 \
          availability-vip-no=2
        
        # 第 3 个 VIP 宿主机：执行安装命令（与其他 VIP 命令中的 availability-vip-no 不同，必须存在一个值为 1）
        ./k8s.sh availability-vip-install \
          availability-vip=192.168.80.100 \
          interface-name=ens33 \
          availability-master=k8s-master1@192.168.80.81:6443 \
          availability-master=k8s-master2@192.168.80.82:6443 \
          availability-master=k8s-master3@192.168.80.83:6443 \
          availability-vip-no=3
        ```

    2. 主节点：***第一台机器***：安装软件、初始化集群

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        
        # 指定 VIP 进行 k8s 集群 第一个主节点 初始化
        ./k8s.sh availability-vip=192.168.80.100
        
        # 安装 Metrics Server 插件（仅第一个主节点执行即可）
        # ./k8s.sh availability-vip=192.168.80.100 metrics-server-install metrics-server-availability
        ```

    3. 主节点：***其余机器***：安装软件、使用主节点角色加入集群

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        
        # 执行安装命令，仅安装，不进行初始化
        ./k8s.sh kubernetes-init-skip calico-init-skip
        
        # 运行 k8s 集群 第一个主节点 初始化完成后 使用主节点角色加入集群的命令，例如：
        # kubeadm join 192.168.80.100:9443 --token ykrnfh.i4qwth17fopc0gtx \
        #   --discovery-token-ca-cert-hash sha256:9e81fa0b04a57517feb1c9e34edc0aa6563b64db54887fc072a08d7d1235861d \
        #   --control-plane --certificate-key 7c3cb3aaedcadfc636b7d476e3fb564a0985eadffe68e9e74c21bab38f007479

        # 也可以在已正常运行的主节点运行下列命令后，将结果拼接成上方示例
        # kubeadm token create --print-join-command
        # kubeadm init phase upload-certs --upload-certs

        # 添加环境变量
        sudo bash -c "echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> /etc/profile"
        # 刷新环境变量
        source /etc/profile
        
        # 命令自动补充
        kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl >/dev/null
        sudo chmod a+r /etc/bash_completion.d/kubectl
        source ~/.bashrc
        
        # 等待 pod 就绪
        kubectl wait --for=condition=Ready --all pods --all-namespaces --timeout=600s
        
        ```

    4. 工作节点：安装软件、使用工作节点角色加入集群

       工作节点 至少需要部署**2**台机器（请保证单个工作节点的资源可以负载所有任务，否则请增加工作节点）

       每个工作节点执行的命令相同

        ```shell
        # 下载脚本，下载后的文件名为 k8s.sh
        curl -o k8s.sh https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/raw/SNAPSHOT/0.2.0/k8s.sh
        # 授权
        chmod +x k8s.sh
        
        # 执行安装命令，仅安装，不进行初始化
        ./k8s.sh kubernetes-init-skip calico-init-skip
        
        # 执行在主节点得到的工作加入集群的命令，例如：
        # kubeadm join 192.168.80.100:9443 --token ykrnfh.i4qwth17fopc0gtx --discovery-token-ca-cert-hash sha256:9e81fa0b04a57517feb1c9e34edc0aa6563b64db54887fc072a08d7d1235861d
        
        # 可使用 kubeadm token create --print-join-command 创建工作节点加入集群的命令
        
        ```

## 常见问题

1. ImagePullBackOff：Docker 镜像拉取失败，解决办法如下：
    1. 等待 k8s 自己重试（时间较久）
    2. 删除 pod，删除后，k8s 会根据需求，选择性创建 Pod（不懂时慎用）
        1. kube-system 命名空间的，都会自动创建
        2. 属于 Deployment 的 pod，都会自动创建
        3. 命令

            ```shell
            kubectl -n 命名空间 delete pod Pod的名称
            ```
    3. 如果根据上方尝试很多次，都拉取不下来，请自行拉取镜像并导入到 k8s 中，代码可参考
        1. [Docker Images 迁移](https://xuxiaowei-tools.gitee.io/#/docker/images/migrate)

2. 高可用主节点总数量与可用数量
    1. 主节点总数量推荐奇数个
    2. 主节点可用数量需要***大于总数量的一半***，集群才能正常运行
        1. 假设1：存在三个主节点，宕机一个主节点后可正常运行，宕机两个主节点后不可正常运行
        2. 假设2：存在四个主节点，宕机一个主节点后可正常运行，宕机两个主节点后不可正常运行
        3. 假设3：存在五个主节点，宕机一个主节点后可正常运行，宕机两个主节点后可正常运行，宕机三个主节点后不可正常运行

3. 如果考虑使用高可用，但是当前机器数量不满足要求，如何进行配置？

- 假设现在只有一台机器，现在需要安装和使用 k8s，一台机器不满足高可用的配置要求。三个月后，才能新增几台机器，三个月后后能满足高可用的要求，现在怎么安装？

    - 方案1（不推荐）：先在现有机器上安装单节点版。新增机器后，将原有机器中的 k8s 重置（k8s 数据会丢失），重新安装 k8s 高可用集群。

    - 方案2（不推荐）：新增机器后，在新机器中安装 k8s 高可用集群，原有机器中的 k8s 单节点版保留，同时保留两个
      k8s（管理困难，数据孤岛，资源孤岛）。

    - 方案3（推荐）：先在现有机器上，安装 <strong><font color="red">伪高可用</font></strong> k8s
      集群，实际上是单节点安装。新增机器后，无缝拓展为真正的高可用。
        1. 只有一台机器时
            1. 在这台机器上创建 VIP
            2. 使用 VIP 创建 k8s 主节点
            3. 主节点去污后，正常使用单机资源
        2. 新增机器后
            1. 修改以前机器上的 VIP 配置，增加主节点配置
            2. 在新机器上创建 VIP（增加主节点后的配置）
            3. 新增的主节点 使用 VIP 和 主节点角色 加入到集群中
            4. 新增的工作节点 使用 VIP 和 工作节点角色 加入到集群中

## 各分支的作用

- main
    1. 主分支，安装脚本以此分支为准
- images-mirrors/\*.\*.\*-0
    1. docker 镜像加速计划，镜像地址：https://jihulab.com/xuxiaowei-cloud/xuxiaowei-cloud/container_registry
    2. docker 镜像离线安装计划：可在 [流水线](https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/pipelines) 产物中，下载所需
       Docker 镜像文件
    3. 有效期默认 30 天，可重试 [流水线](https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/pipelines) 重新生成
    4. 可自行 fork 本项目，修改配置，生成自己所需 Docker 镜像文件
    5. 可创建议题、PR，生成所需 Docker 镜像文件
- yum/\*.\*.\*-0
    1. yum 离线安装计划：可在 [流水线](https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/pipelines) 产物中，下载所需安装
       k8s、docker 等相关软件的 yum 离线安装包
    2. 有效期默认 30 天，可重试 [流水线](https://jihulab.com/xuxiaowei-com-cn/k8s.sh/-/pipelines) 重新生成
    3. 可自行 fork 本项目，修改配置，生成自己所需安装 k8s、docker 等相关软件的 yum 离线安装包
    4. 可创建议题、PR，生成所需 yum 离线安装包
- xuxiaowei*
    1. 个人分支
- test*
    1. 测试分支
