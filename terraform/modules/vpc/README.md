# Module: `vpc`

Creates a **multi-AZ** VPC with:

- **Public** subnets (one `/24` per AZ under the VPC CIDR: indices `0 … az_count-1`)
- **Private** subnets (indices `10 … 10+az_count-1` — e.g. `10.0.10.0/24` when VPC is `10.0.0.0/16`)
- **Internet gateway** + public route table
- **NAT gateway(s)** — one shared (`single_nat_gateway = true`, default) or one per AZ

Subnet tags include `kubernetes.io/role/elb` / `kubernetes.io/role/internal-elb` for **EKS** load balancers. Optional `eks_cluster_name` adds the `kubernetes.io/cluster/<name>` tag.

## Inputs (summary)

| Name | Default | Notes |
|------|---------|--------|
| `name_prefix` | — | Required; used in Name tags |
| `vpc_cidr` | `10.0.0.0/16` | Must fit `/8` split used by `cidrsubnet(..., 8, …)` |
| `az_count` | `3` | Uses first N AZs (capped by what the region exposes); max **4** |
| `single_nat_gateway` | `true` | `false` = NAT per AZ |
| `eks_cluster_name` | `null` | Set when subnets must be tagged for a named EKS cluster |

## Architecture

### Default (`single_nat_gateway = true`)

One **NAT Gateway** in the **first** public subnet; **one** private route table shared by all private subnets. **One** public route table shared by all public subnets.

```mermaid
flowchart TB
  inet((Internet))

  subgraph vpc["VPC — var.vpc_cidr"]
    igw[Internet Gateway]

    subgraph pub["Public subnets — cidrsubnet /8 index 0…N-1"]
      p1["public-1 / AZ-a"]
      p2["public-2 / AZ-b"]
      pn["…"]
    end

    subgraph natg["NAT"]
      eip[EIP]
      nat[NAT Gateway]
    end

    subgraph prv["Private subnets — cidrsubnet /8 index 10…10+N-1"]
      v1["private-1 / AZ-a"]
      v2["private-2 / AZ-b"]
      vn["…"]
    end

    rt_pub["Public route table<br/>0.0.0.0/0 → IGW"]
    rt_prv["Private route table<br/>0.0.0.0/0 → NAT"]
  end

  inet <--> igw
  igw --> rt_pub
  p1 & p2 & pn --> rt_pub
  v1 & v2 & vn --> rt_prv
  rt_prv --> nat
  nat --> eip
  nat -.->|"placed in"| p1
```

Traffic: **private** → private RT → **NAT** → **public subnet** → public RT → **IGW** → internet. **Public** workloads use public RT → IGW directly.

### `single_nat_gateway = false`

Same layout, but **one EIP + one NAT per AZ**, each NAT in the **matching** public subnet; **one private route table per AZ** associated with the private subnet in that AZ (default route to the NAT in the same AZ).

```mermaid
flowchart LR
  subgraph per_az["Per AZ (× az_count)"]
    direction TB
    pub_i[Public subnet]
    prv_i[Private subnet]
    eip_i[EIP]
    nat_i[NAT]
    rt_p_i[Public RT → IGW]
    rt_v_i[Private RT → NAT]
    pub_i --> rt_p_i
    prv_i --> rt_v_i
    rt_v_i --> nat_i
    nat_i --> eip_i
    nat_i --> pub_i
  end
```
