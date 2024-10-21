## 为集群创建ACL

1. consul acl bootstrap
记录SecretID
可以将该id作为环境变量，写入.bashrc中
export CONSUL_HTTP_TOKEN=xxxxxx

2. consul acl policy create  -name "agent-token" -description "Agent Token Policy" -rules @agent-policy.hcl


agent-policy.hcl
```shell
node_prefix "" {
   policy = "write"
}
service_prefix "" {
   policy = "read"
}
```

3. 创建agent token ,将这个token分发给server或者clinet 才可以正常接入，并使用对应功能。 
consul acl token create -description "Agent Token" -policy-name "agent-token"

记录secretId 配置到server或者clinet上。 