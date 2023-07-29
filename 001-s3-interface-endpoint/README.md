# AWS S3 Interface Endpoint 
 
The main goal of s3 interface endpoint to enable private communication(l4) between services running on VPC and s3. 
After configuring s3 interface endpoint the public dns name for s3 service is resolved to private ip address(s). 

#### High level diagram
- Once you create a s3 VPC endpoint and associate it with one or more subnet, A new ENI is created for each subnet. 
- You must enable Private DNS for this endpoint if you want the public dns name for s3 to be resolved to private ip address
- You need to configure routing for s3 VPC endpoint to work, default routing rules are sufficient.  
- Network L4 access is controlled by a security group associated to this VPC endpoint. 
- Network L7 access is controlled by Endpoint policy 
- This endpoint is not a *gateway*, it is an interface endpoint.
- S3 interface endpoint is not highly available, you need to create one for each AZ.


![s3-gateway-endpoint.svg](s3-interface-endpoint.svg)

#### This terraform code is an example of configuring s3 endpoint and allow an instance to resolve s3 public endpoint to local VPC dns name. 
```bash
terraform apply
```