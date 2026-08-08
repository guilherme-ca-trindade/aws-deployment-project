# Cost Analysis

Supporting calculations for `cost-analysis.png`.

Region: **us-east-1**, on-demand pricing, **730 hours** per month.
Configuration taken from the resources actually deployed in this project (see
`resource-descriptions.txt`): `t2.nano`, 8 GiB gp3 root volume, Lambda at 128 MB / x86_64.

## Monthly cost of the running resources

| Service | Configuration | Rate | Monthly |
|---|---|---|---|
| EC2 instance | t2.nano, Linux, 24/7 | $0.0058 / hr | $4.23 |
| EBS storage | 8 GiB gp3 (3000 IOPS + 125 MB/s are included in the baseline) | $0.08 / GB-mo | $0.64 |
| Public IPv4 | 1 in-use address, 24/7 | $0.005 / hr | $3.65 |
| **EC2 subtotal** | | | **$8.52** |
| DynamoDB | on-demand, 1 write per roll, <1 KB items | $1.25 / M writes | ~$0 at lab volume |
| VPC gateway endpoint | DynamoDB gateway endpoint | free | $0.00 |
| Internet gateway | (only data transfer is billed) | free | $0.00 |
| Lambda | 128 MB, only invoked during testing | see below | ~$0 at lab volume |

Gateway endpoints are free — only *interface* (PrivateLink) endpoints carry an hourly charge.
This is worth noting because it means routing DynamoDB traffic privately costs nothing here.

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
| Full cost of running the instance (instance + EBS + public IP) | $8.52 | **~20.9 million** | ~8 req/sec |
| Instance compute charge only | $4.23 | ~10.4 million | ~4 req/sec |

**DynamoDB is deliberately left out of this comparison.** Both options write exactly one
item per dice roll, so that charge is identical either way and cancels out of the break-even.

If the Lambda free tier is applied (1M requests + 400,000 GB-seconds per month, which covers
duration up to 32M requests at this size), break-even against the $8.52 figure moves out to
about **37.7 million** requests per month. The AWS Pricing Calculator does not apply the free
tier by default, so the ~20.9 million figure is the one that matches a default estimate.

## Caveat worth stating

The break-even is a *pricing* result, not a capacity one. ~8 requests/second sustained is far
more than a single `t2.nano` running one gunicorn sync worker would actually serve. In
practice you would have had to scale the EC2 side up (larger instance, more instances, a load
balancer) long before reaching the crossover, which pushes the real-world break-even much
higher in Lambda's favour for this bursty, low-volume workload.

## Text to paste into the Pricing Calculator "Description" field

> Lambda vs EC2 break-even. Running the EC2 instance costs $8.52/month (t2.nano $4.23 +
> 8 GB gp3 EBS $0.64 + in-use public IPv4 $3.65). One Lambda request at 128 MB / 100 ms costs
> $0.0000002 (request) + $0.000000208 (0.0125 GB-s duration) = $0.000000408. Break-even =
> $8.52 / $0.000000408 = ~20.9 million requests/month, about 8 requests/second sustained.
> Against the t2.nano compute charge alone ($4.23) it is ~10.4 million requests/month.
> DynamoDB is excluded because both options write one item per roll, so that cost is
> identical either way.

> **Note:** verify these rates against the AWS Pricing Calculator when you build the estimate —
> the screenshot is the graded artifact, and published prices change.
