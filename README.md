# Scalable Web Application - EC2 Based Architecture

This repository contains a well-structured, scalable, and highly available **AWS EC2-based web application architecture**. It includes both the **final PNG diagram with CIDR labels** and the **editable draw.io source file (XML format)**.

---

## 🧩 Components Overview

- **Region:** N. Virginia (`us-east-1`)
- **VPC CIDR Block:** `10.0.0.0/16`

---

### 🔷 Subnet Allocation (CIDR Blocks)

| **Purpose**            | **AZ1 (us-east-1a)** | **AZ2 (us-east-1b)** |
|------------------------|----------------------|----------------------|
| Public Subnet          | `10.0.0.0/24`        | `10.0.1.0/24`        |
| Private App Subnet     | `10.0.2.0/24`        | `10.0.3.0/24`        |
| Private DB Subnet      | `10.0.4.0/24`        | `10.0.5.0/24`        |

---

## 🛠️ Architecture Components

### 🔐 Networking
- **Internet Gateway:** Enables internet access for resources in public subnets.
- **NAT Gateway (Optional):** Allows private subnets to initiate outbound traffic to the internet.
- **Route Tables:** Associated with public and private subnets accordingly.

### 📦 Compute
- **Amazon EC2 Instances:** Hosts the application backend inside private subnets.
- **Auto Scaling Group:** Maintains availability and scales the EC2 fleet based on load.

### ⚖️ Load Balancing
- **Application Load Balancer (ALB):** Distributes incoming HTTP/S traffic to EC2 instances.

### 💾 Database Layer
- **Amazon RDS (Multi-AZ):**
  - **Primary:** In `10.0.4.0/24`
  - **Standby:** In `10.0.5.0/24`
  - Automatic backups, failover, and read replicas.

### 🧑‍💻 Bastion Host
- **Deployed in Public Subnet**
- Allows secure SSH access to EC2 instances in private subnets.
- Admin IAM user access only.

---

## 👤 Identity & Access Management (IAM)

| **Role**    | **Access**                |
|-------------|---------------------------|
| Admin       | Full access via Bastion   |
| EC2 Role    | Access to CloudWatch, S3  |
| RDS Role    | Managed by AWS            |

---

## 📊 Monitoring & Logging

- **Amazon CloudWatch:** 
  - Monitors EC2, RDS, ALB health
  - Triggers alarms and notifications
- **SNS Alerts:** Sends notifications to subscribed admins on critical events.

---

## 🧑‍💻 Admin Access Process

1. Admin authenticates via IAM.
2. Connects to the **Bastion Host** (public subnet).
3. SSH to private EC2 instances using internal IP.
4. All actions are logged and monitored.

---

## 📁 Repository Structure

scalable-webapp-infra/
├── diagram/
│ ├── labeled-architecture.png # Final labeled AWS architecture diagram
│ └── architecture-drawio.xml # Editable source file (draw.io format)
├── README.md # This documentation

---

## 🧠 Best Practices Followed

✅ Multi-AZ Deployment  
✅ Private Subnet Isolation  
✅ Least Privilege IAM Policies  
✅ Auto Scaling and Load Balancing  
✅ Bastion Host for secure SSH  
✅ Cloud-native monitoring & alerting  
✅ Clean CIDR and subnet planning  

---

## 📷 Preview

![Scalable AWS Web Application Architecture](diagram\AutoScalingWebApp.jpg)

---

## ✍️ Author

**Mohamed Maged**  
DevOps & Cloud Enthusiast  
[LinkedIn](https://www.linkedin.com/in/magedo)  
[Email](mailto:mohamed.ibn.maged@gmail.com)


---

## 💡 Notes

- You can open the XML file in [draw.io](https://draw.io) or [diagrams.net](https://app.diagrams.net) for further customization.
- Feel free to fork this project and adapt it to your own infrastructure designs.