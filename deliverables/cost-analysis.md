# Cost Analysis

Supporting calculations for `cost-analysis.png`.
https://calculator.aws/#/estimate?id=89aa686de81df48c62171d8fd45b72d04c29915f

Region: **us-east-1**, on-demand pricing, **730 hours** per month.
Configuration taken from the resources actually deployed in this project (see
`resource-descriptions.txt`): `t2.nano`, 8 GiB gp3 root volume, Lambda at 128 MB / x86_64.

## Monthly cost of the running resources

| Service | Configuration | Rate | Monthly |
|---|---|---|---|
| EC2 instance | t2.nano, Linux, 24/7 | $0.0058 / hr | $4.23 |
| EBS storage | 8 GiB gp3 (3000 IOPS + 125 MB/s are included in the baseline) | $0.08 / GB-mo | $0.64 |
| **EC2 subtotal (as estimated)** | | | **$4.87** |
| DynamoDB | on-demand, 1 write per roll, <1 KB items | $1.25 / M writes | ~$0 at lab volume |
| VPC gateway endpoint | DynamoDB gateway endpoint | free | $0.00 |
| Internet gateway | (only data transfer is billed) | free | $0.00 |
| Lambda | 128 MB, only invoked during testing | see below | ~$0 at lab volume |

Gateway endpoints are free — only *interface* (PrivateLink) endpoints carry an hourly charge.
This is worth noting because it means routing DynamoDB traffic privately costs nothing here.

**One charge the estimate does not include:** since February 2024 AWS bills every *in-use*
public IPv4 address at $0.005/hr, which is another **$3.65/month** for this instance. Counting
it, the true cost of running the EC2 instance is **$8.52/month**. Both figures are carried
through the break-even below.

## Break-even: how many Lambda requests equal the EC2 instance?

Cost of one Lambda request at 128 MB (0.125 GB) with an assumed **100 ms** billed duration:

    request charge   $0.20 per 1M            = $0.000000200
    duration charge  0.125 GB x 0.1 s        = 0.0125 GB-s
                     0.0125 x $0.0000166667  = $0.000000208
                                              ---------------
    total per request                         = $0.000000408

Break-even against the EC2 cost:

| Compared against | EC2 monthly | Break-even requests / month | Sustained rate |
|---|---|---|---|
| The estimate as built (instance + EBS) | $4.87 | **~11.9 million** | ~4.5 req/sec |
| Adding the in-use public IPv4 charge | $8.52 | ~20.9 million | ~8 req/sec |

The **~11.9 million** figure is the headline answer, because it is the one that matches the
total shown in the Pricing Calculator estimate.

**DynamoDB is deliberately left out of this comparison.** Both options write exactly one
item per dice roll, so that charge is identical either way and cancels out of the break-even.

If the Lambda free tier is applied (1M requests + 400,000 GB-seconds per month, which covers
duration up to 32M requests at this size), break-even against the $4.87 figure moves out to
about **25.4 million** requests per month. The AWS Pricing Calculator does not apply the free
tier by default, so the ~11.9 million figure is the one that matches the estimate.

## Caveat worth stating

The break-even is a *pricing* result, not a capacity one. ~4.5 requests/second sustained is
far more than a single `t2.nano` running one gunicorn sync worker would actually serve. In
practice you would have had to scale the EC2 side up (larger instance, more instances, a load
balancer) long before reaching the crossover, which pushes the real-world break-even much
higher in Lambda's favour for this bursty, low-volume workload.

## Text used in the Pricing Calculator "Description" field

> Break-even ~11.9M requests/month. EC2 = $4.87/mo (t2.nano $4.23 + 8GB gp3 $0.64). Lambda
> at 128MB/100ms = $0.0000002 request + $0.000000208 duration = $0.000000408 each.
> $4.87 / $0.000000408 = ~11.9M requests/month (~4.5 req/sec). DynamoDB excluded: both
> options write 1 item per roll, so it cancels out.

