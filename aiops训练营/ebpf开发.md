![img](./assets/1740563835348-6e459ed7-7b91-4d1b-ba35-2e97900bac33.png)



![img](./assets/1740563900455-47326cda-fe24-4bbd-b9f4-a081d44ad4c6.png)



![img](./assets/1740563909778-43a0e514-1f67-418f-b970-776e2f196720.png)



![img](./assets/1740564097759-1c116246-c4bb-40c1-b2e8-84f3bf232376.png)



![img](./assets/1740564157343-325aa38d-94f5-4cc1-abc4-e1a40da639e0.png)



![img](./assets/1740564185297-227ef6e9-6657-496a-bd10-d31a7d20d8dc.png) 



![img](./assets/1740564283478-8a83c387-9fc3-4461-8693-15499fac28cf.png)



![img](./assets/1740564952599-3b84f75c-5d24-413f-a72f-0996976440d6.png)



![img](./assets/1740564986719-e7cd9fc1-6a38-417d-ba2a-a38eeb06303e.png)





 ![img](./assets/1740565020038-33fb9859-0d1a-4d66-ae26-ed18ec197ba5.png)



![img](./assets/1740568599184-84a38f0a-9ec6-4bca-a390-c2ce4b483a01.png)



抓取某一个进程  在内核层面 处理http请求 消耗的事件 

```plain
from bcc import  BPF
import  time
##解析命令行参数
import  argparse
#构造 一个命令行参数解析器 用于接收用户输入的希望监控的目标进程PID
parser=argparse.ArgumentParser(
   description="PID"
)

##添加-p 或者--Pid
parser.add_argument(
    "-p","--pid", type=int,required=True,help="yhe pid of go process"
)

#从命令行解析用户输入的参数
arg=parser.parse_args()
target_pid=args.pid

#定义ebpf程序
bpf_text="""
#include <upai/linux/ptarce.h>  #ebpf程序需要的用户态的头文件
#include <linux/sched.h> //提供调度程序相关的结构体的定义
//定义一个结构体用来存储跟踪数据，把数据从内核态发送到用户态
struct data_t {
  u32 pid; //进程id
  u64 latency; //延迟时间
  char commm[TASK_COMM_LEN]; //进程名
};
// 定义一个哈希表用来存储每个pid的开始时间戳
BPF_HASH(start,u32);
//定义一个缓冲区，用来把时间传递到用户态
BPF_PERF_OUTPUT(events);

//定义ebpf函数，触发点tcp——sendmsg 表示发送tcp消息的时候
int  tarce_start(struct pt_regs *ctx,struct sock *sk){
  //获取当前进程的pid
  u32 pid= bpf_get_current_pid_tgid() >>32;

  //只跟踪目标的pid
  if （pid！= TARGET_PID）{
    return 0;
  }
  // 获取内核的时间戳 （单位是 ns）
  u64 ts =bpf_ktime_get_ns();
  //事件戳存放到哈希表，键pid，值是时间戳
   start.update(&pdi,&ts);

   return 0;
}
//另一个结束触发点,tcp_cleanup_rbuf
int trace_end(struct pt_regs *ctx,struct sock *sk){
  //获取当前进程的pid
  u32 pid =bpf_get_current_pid_tgid() >>32;
  // 只追踪目标pid
  if （pid ！=TARGENT_PID）{
     return 0；
  }
   // 从哈希表查找之前记录的开始时间戳
   u64 *tsp =start.lookup(&pid);

   //没有找到开始的时间戳，可能是错过了start事件，直接返回
   if （tsp==0）{
     return 0；
   }
   // 计算延迟，当前时间戳减去开始的时间戳
   u64 delta=bpf_ktime_get_ns() -*tsp;
   //删除哈希表的记录，因为数据已经用了
   start.delete(&pid);

   //初始化一个结构，用来存储并发送事件
   struct data_t data ={}
   data.pid =pid;
   data.latency= delta;
   bpf_get_current_commm(&data.comm,sizeof(data.comm));

   //把收集到的数据发送到用户态
   events.perf_submit(ctx,&data,sizeof(data))

   
}
"""

##替换ebpf程序中的占位符 TARGET_PID 
bpf_text=bpf_text.replace("TARGET-PID",str(target_pid))

#加载
b=BPF(text=bpf_text)

#trace_start 添加到tcp_sendmsg 内核函数
b.attch_kprobe(event="tcp_sendmsg",fn_name="trace_start")
b.attch_kprobe(event="tcp_cleanup_rbuf",fn_name="trace_end")


##定义回调函数，处理ebpf程序发送到用户态的事件
def print_ebent(cpu,data,size):
   event = b["events"].event(data)
   print(
      f"[{time.strftime('%H:%M:%S')}] PID:{event.pid}, COMM:{event.comm.decode('utf-8','replace')},Latency:{event.latency/ 1e6:.2f}" 
   )

b["events"].open_perf_buffer(print_event)

#输出提示信息
print（f"Tracing HTTP Request For PID {target_pid}"）

##写一个无限循环
while True：
   try：
      b.perf_buffer_poll()
   except KeyboardInterrupt:
       exit()
```



#  Beyla 

![img](./assets/1740579271011-4e8a69ca-bd8f-49d7-b29f-91aa50e2a1b8.png)

![img](./assets/1740579317403-20c31335-aef0-45ec-91a5-cf265d9d0d65.png)

![img](./assets/1740579373387-50560a44-cbc2-45b0-aa15-0982dae771ae.png)



![img](./assets/1740579389553-cbc0b0b6-fec7-48c0-a8c4-d4849e907220.png)

![img](./assets/1740579442514-e32b00be-5210-4956-a02a-8cdfd1c60d95.png)





![img](./assets/1740579495270-50d57340-d89f-4c92-a0d2-cd4213fdb554.png)

ebpf 会记录到 自己服务在内部队列等待的时间   这样更精准 

![img](./assets/1740579579991-72821f80-472c-4a9d-b35f-15c680f812db.png)

![img](./assets/1740579599330-15f04108-e86d-48e7-882b-f1a27a811ea8.png)



![img](./assets/1740579709454-fdd16f36-fa41-4269-b036-7823b5e2ec25.png)



![img](./assets/1740579757412-45af4d09-98c1-41e3-8bec-a67793387b28.png)



最后得到的反馈是 无代码层面的侵入可以得到ebpf的反馈的指标 

![img](./assets/1740580327952-714b7f8d-027b-4dc4-aedb-5dda1fb40f2e.png)

![img](./assets/1740580806213-7e17ec4e-d719-426b-9c95-48c7b0084830.png)![img](./assets/1740580846013-da61cdea-02af-40bb-8d68-f54f9d809149.png)



![img](./assets/1740580949723-a33f5c78-82e6-42e7-af72-e4e7242c0ab8.png)







cilium 

![img](./assets/1740581949789-dcd4a9f1-30bc-4b11-89a3-f1595debc44c.png)

![img](./assets/1740581967539-3c5b1a2a-f690-4918-b618-6f4aa4113a7e.png)



![img](./assets/1740582027455-5e46fa76-cd56-4054-a38e-74561ae82d8a.png)



![img](./assets/1740582081692-bd30a233-f3c1-408a-964c-f1fd7d5f138e.png)



![img](./assets/1740582108040-4b1544da-ffcf-4279-90f8-79641416c309.png) 

![img](./assets/1740582233763-73383175-47eb-4e96-b402-b2f780a05593.png)





![img](./assets/1740582258295-107f1e0f-b332-4b95-9a45-6d0e94603f48.png)



![img](./assets/1740582299252-bab0c676-4906-4515-9046-b62e87d749fe.png)



![img](./assets/1740582318400-42c4960f-29b9-4328-b902-29a2b7cec821.png)



![img](./assets/1740582459769-c49365fb-0fd8-440a-af7e-9f08678eafac.png)





最后的效果

![img](./assets/1740582727274-c1222c8a-3f61-47e1-98c4-8e140345bb7b.png)

生成拓扑







# ebpf+elaco 实时监控k8s安全威胁

![img](./assets/1740582791259-62716826-1b1e-45b0-815a-b7e79a06dab4.png)



![img](./assets/1740582846470-3a9bb81e-1268-4860-8fb8-44db54365cc3.png)

![img](./assets/1740582877368-3d3f5fb0-8b85-4112-b284-973a3de380b1.png)

![img](./assets/1740583035714-d984b5ac-276f-4090-aa16-b3e6c1059a88.png)



![img](./assets/1740583133936-49c81377-baca-4655-8d74-537a586f5280.png)

![img](./assets/1740583150201-d85957ca-14ef-4a94-856f-8d6a5f4f4aed.png)

![img](./assets/1740583184335-253da566-8018-4733-b2fd-ce81780c0e81.png)



![img](./assets/1740583262257-26f1c001-543d-47aa-9c4b-fe3e3778a9c5.png)