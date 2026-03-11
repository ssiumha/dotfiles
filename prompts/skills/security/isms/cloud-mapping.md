# 클라우드 ISMS-P 매핑 가이드

> 클라우드 환경 ISMS-P 인증을 위한 CSP 서비스 매핑

## 개요

클라우드 서비스 사용 시 ISMS-P 인증에서 요구하는 통제 항목을 CSP(Cloud Service Provider) 서비스로 구현하는 방법을 안내합니다.

### 클라우드 ISMS-P 인증 현황

| CSP | 인증 현황 | 비고 |
|-----|----------|------|
| AWS | K-ISMS 인증 (2018~) | 서울 리전 110+ 서비스 |
| Azure | ISO 27001, SOC 2, CSA STAR | Korea Central/South 리전 |
| GCP | - | 개별 확인 필요 |

---

## AWS ISMS-P 매핑

### 2.5 인증 및 권한관리

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.5.1 | 사용자 계정 관리 | IAM | 불필요 계정 제거, 역할별 권한 분리 |
| 2.5.2 | 사용자 식별 | IAM, CloudTrail | 개별 사용자 식별, API 호출 로깅 |
| 2.5.4 | 비밀번호 관리 | IAM Password Policy | 복잡도, 만료, 재사용 제한 설정 |
| 2.5.5 | 특수 계정 관리 | IAM, Organizations | Root 미사용, MFA 필수, 권한 최소화 |

**주요 점검사항**:
- Root 계정 MFA 설정 여부
- IAM 사용자별 개별 계정 생성 여부
- Access Key 주기적 교체 여부
- 미사용 계정/권한 정리 여부

### 2.6 접근통제

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.6.1 | 네트워크 접근 | VPC, Security Group, NACL | 3계층 분리, 인바운드/아웃바운드 제어 |
| 2.6.2 | 정보시스템 접근 | EC2, RDS | VPC 내 배치, 퍼블릭 IP 제한 |
| 2.6.6 | 원격접근 통제 | Session Manager, Bastion | SSH 직접 접근 제한, 감사 로깅 |
| 2.6.7 | 인터넷 접속 통제 | AWS WAF, Network Firewall | 웹 방화벽, 트래픽 필터링 |

**주요 점검사항**:
- Security Group ANY 규칙 제거
- Private Subnet 활용 여부
- Bastion Host 또는 Session Manager 사용
- NAT Gateway 통한 아웃바운드 제어

### 2.7 암호화 적용

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.7.1 | 암호정책 적용 | KMS | 암호키 중앙 관리, 키 교체 정책 |
| 2.7.2 | 암호키 관리 | KMS, Secrets Manager | 키 생성/보관/폐기, 비밀 관리 |

**저장 데이터 암호화**:
| 서비스 | 암호화 방법 |
|--------|------------|
| S3 | SSE-S3, SSE-KMS, SSE-C |
| EBS | KMS 기반 암호화 |
| RDS | KMS 기반 암호화 (스토리지 + 스냅샷) |

**전송 데이터 암호화**:
- TLS 1.2 이상 적용
- ACM (Certificate Manager) 활용

### 2.10 시스템/서비스 보안관리

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.10.2 | 클라우드 보안 | 전체 | 클라우드 보안 지침 수립, CSP 책임 분담 |

**책임 분담 모델**:
| 구분 | AWS 책임 | 고객 책임 |
|------|---------|----------|
| 물리 보안 | O | - |
| 네트워크 인프라 | O | - |
| OS/네트워크 설정 | - | O |
| 데이터 암호화 | - | O |
| IAM 관리 | - | O |

**주의**: CSAP 인증 CSP 사용 시에도 물리보안 증적 제시 필요

### 2.9 시스템/서비스 운영관리

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.9.1 | 변경관리 | Config, CloudFormation | 인프라 변경 추적, IaC 적용 |
| 2.9.4 | 로그 및 접속기록 관리 | CloudTrail, CloudWatch | API 로깅, 로그 보관 기간 설정 |

**로그 보관 기간**:
| 로그 유형 | 최소 보관 기간 |
|----------|---------------|
| 개인정보 접속기록 | 1년 (5만명 이상: 2년) |
| CloudTrail 로그 | 90일 기본, S3로 장기 보관 |

### 2.10 + 2.11 보안관리 및 사고대응

| 항목 | 항목명 | AWS 서비스 | 설정 가이드 |
|------|--------|-----------|------------|
| 2.10.1 | 보안시스템 운영 | GuardDuty, Inspector | 위협 탐지, 취약점 스캔 |
| 2.11.3 | 이상행위 분석 및 모니터링 | GuardDuty, Detective | 이상행위 자동 탐지, 조사 |

**보안 서비스 구성**:
```
GuardDuty (위협 탐지)
    ↓
Security Hub (통합 대시보드)
    ↓
EventBridge → SNS (알림)
    ↓
Detective (조사)
```

---

## AWS Config 규정준수팩

AWS는 K-ISMS-P 컴플라이언스를 위한 Config 규정준수팩을 제공합니다.

### 주요 규칙

| 규칙명 | 매핑 항목 | 설명 |
|--------|----------|------|
| iam-password-policy | 2.5.4 | 비밀번호 정책 준수 확인 |
| iam-user-mfa-enabled | 2.5.5 | MFA 설정 확인 |
| root-account-mfa-enabled | 2.5.5 | Root MFA 확인 |
| vpc-sg-open-only-to-authorized-ports | 2.6.1 | 보안그룹 규칙 확인 |
| encrypted-volumes | 2.7.1 | EBS 암호화 확인 |
| rds-storage-encrypted | 2.7.1 | RDS 암호화 확인 |
| cloudtrail-enabled | 2.9.4 | CloudTrail 활성화 확인 |
| s3-bucket-ssl-requests-only | 2.7.x | S3 TLS 강제 확인 |

**적용 방법**:
1. AWS Config 활성화
2. 규정준수팩 배포 (K-ISMS 운영 모범사례)
3. 비준수 리소스 자동 식별
4. 수동 또는 자동 조치

---

## Azure ISMS-P 매핑

> **NOTE**: 현행(2023.10) 항목 번호 기준. Azure 서비스명은 2024년 기준 (일부 리브랜딩 반영)

### 2.5 인증 및 권한관리

| 항목 | 항목명 | Azure 서비스 | 설정 가이드 |
|------|--------|-------------|------------|
| 2.5.1 | 사용자 계정 관리 | Microsoft Entra ID | 불필요 계정 제거, 역할별 권한 분리 |
| 2.5.2 | 사용자 식별 | Entra ID, Activity Log | 개별 사용자 식별, 감사 로깅 |
| 2.5.3 | 사용자 인증 | Entra ID MFA, Conditional Access | 비밀번호 외 2차 인증 강제 |
| 2.5.4 | 비밀번호 관리 | Entra ID Password Policy | 복잡도, 만료, 재사용 제한 설정 |

**주요 점검사항**:
- Global Admin 계정 MFA 설정 여부
- 사용자별 개별 계정 생성 여부
- Conditional Access 정책 적용 여부
- PIM(Privileged Identity Management) 활성화 여부

### 2.6 접근통제

| 항목 | 항목명 | Azure 서비스 | 설정 가이드 |
|------|--------|-------------|------------|
| 2.6.1 | 네트워크 접근 | VNet, NSG, Azure Firewall | 서브넷 분리, 인바운드/아웃바운드 제어 |
| 2.6.2 | 정보시스템 접근 | VM, SQL Database | VNet 내 배치, Private Endpoint |
| 2.6.6 | 원격접근 통제 | Azure Bastion, Just-In-Time | RDP/SSH 직접 접근 제한, 시간 제한 |
| 2.6.7 | 인터넷 접속 통제 | Azure WAF, Front Door | 웹 방화벽, DDoS 보호 |

**주요 점검사항**:
- NSG ANY 규칙 제거
- Private Subnet 활용 여부
- Azure Bastion 또는 Just-In-Time VM Access 사용
- Service Endpoint / Private Link 활용

### 2.7 암호화 적용

| 항목 | 항목명 | Azure 서비스 | 설정 가이드 |
|------|--------|-------------|------------|
| 2.7.1 | 암호정책 적용 | Azure Key Vault | 키 중앙 관리, 키 교체 정책 |

**저장 데이터 암호화**:
| 서비스 | 암호화 방법 |
|--------|------------|
| Blob Storage | SSE (Microsoft-managed / Customer-managed) |
| Managed Disk | SSE + ADE (Azure Disk Encryption) |
| SQL Database | TDE (Transparent Data Encryption) |

**전송 데이터 암호화**:
- TLS 1.2 이상 강제
- App Service / Front Door 인증서 관리

### 2.9 시스템/서비스 운영관리

| 항목 | 항목명 | Azure 서비스 | 설정 가이드 |
|------|--------|-------------|------------|
| 2.9.1 | 변경관리 | Azure Resource Manager, Policy | IaC(Bicep/ARM), 정책 기반 거버넌스 |
| 2.9.3 | 백업 및 복구관리 | Azure Backup, Site Recovery | 백업 스케줄, RPO/RTO 관리 |
| 2.9.4 | 로그 및 접속기록 관리 | Azure Monitor, Log Analytics | 활동 로그, 진단 로그 수집 |

**로그 보관 기간**:
| 로그 유형 | 기본 보관 | 권장 설정 |
|----------|----------|----------|
| Activity Log | 90일 | Log Analytics로 장기 보관 |
| 진단 로그 | 설정 필요 | Storage Account로 1년+ |

### 2.10 시스템/서비스 보안관리

| 항목 | 항목명 | Azure 서비스 | 설정 가이드 |
|------|--------|-------------|------------|
| 2.10.1 | 보안시스템 운영 | Microsoft Defender for Cloud | 보안 점수, 권장 사항 적용 |
| 2.10.2 | 클라우드 보안 | 전체 | 클라우드 보안 지침 수립, 책임 분담 |

**책임 분담 모델**:
| 구분 | Azure 책임 | 고객 책임 |
|------|-----------|----------|
| 물리 보안 | O | - |
| 네트워크 인프라 | O | - |
| OS/네트워크 설정 | - | O |
| 데이터 암호화 | - | O |
| Entra ID 관리 | - | O |

**보안 서비스 구성**:
```
Microsoft Defender for Cloud (통합 보안)
    ↓
Microsoft Sentinel (SIEM/SOAR)
    ↓
Logic Apps → 알림/자동 대응
```

### Azure Policy 규정준수

Azure는 규정 준수 이니셔티브를 통해 ISMS-P 요구사항을 검증할 수 있습니다.

| 정책 | 매핑 항목 | 설명 |
|------|----------|------|
| Require MFA for admins | 2.5.4 | 관리자 MFA 강제 |
| Storage accounts should use private link | 2.6.1 | Private Endpoint 강제 |
| Disk encryption should be applied | 2.7.1 | 디스크 암호화 확인 |
| Activity log should be retained for at least one year | 2.9.4 | 로그 보관 기간 확인 |
| Microsoft Defender for Cloud should be enabled | 2.10.1 | 보안 센터 활성화 |

---

## 금융권 특화 안내

금융권(은행, 증권, 보험, 전자금융업자)은 일반 ISMS-P 외 추가 요구사항이 있습니다.

### 적용 대상
- 전자금융거래법 적용 대상
- 신용정보법 적용 대상
- 금융회사 및 신용정보회사
- 전자금융업자

### 금융보안원 점검항목 (399개)

| 구분 | 일반 ISMS-P | 금융권 ISMS-P |
|------|------------|---------------|
| 항목 수 | 101개 | 399개 (세부점검항목) |
| 인증기관 | KISA | 금융보안원 (FSI) |
| 추가 법령 | - | 전자금융거래법, 신용정보법 |

### 클라우드 사용 시 추가 의무

| 항목 | 내용 |
|------|------|
| 금감원 보고 | 클라우드 이용 시 3개월 내 보고 |
| CSP 평가 | 금융보안원 클라우드 보안 평가 |
| 계약 요건 | 전자금융감독규정 요구사항 반영 |

### 자료 다운로드

- [금융보안원 ISMS-P 점검항목 (399개)](https://www.fsec.or.kr/bbs/detail?menuNo=247&bbsNo=11386)
- [금융권 클라우드 보안관리 참고서](https://www.fsec.or.kr/bbs/detail?menuNo=222&bbsNo=11801)

---

## 실무 사례

### 우아한형제들 Hybrid-Cloud ISMS 인증 사례

하이브리드 클라우드 환경에서 ISMS 인증을 준비한 실무 사례입니다.

**환경**:
- On-premise + AWS 하이브리드
- 마이크로서비스 아키텍처

**주요 대응**:
1. 네트워크 분리: VPC + Direct Connect
2. 접근통제: IAM + On-premise LDAP 연동
3. 로그 통합: CloudWatch + On-premise SIEM
4. 암호화: KMS + On-premise HSM 연계

---

## 체크리스트

클라우드 환경 ISMS-P 준비 시 확인사항 (현행 항목 번호 기준):

### 계정/권한 (2.5.x)
- [ ] 관리자 계정 MFA 설정 (AWS: Root / Azure: Global Admin)
- [ ] 사용자별 개별 계정 생성 (AWS: IAM / Azure: Entra ID)
- [ ] 자격 증명 주기적 교체 (AWS: Access Key / Azure: Service Principal)
- [ ] 미사용 계정/권한 정리
- [ ] 비밀번호 정책 설정

### 네트워크 (2.6.x)
- [ ] 3계층 분리 (AWS: VPC / Azure: VNet)
- [ ] 보안그룹 ANY 규칙 제거 (AWS: SG / Azure: NSG)
- [ ] 개인정보처리시스템 Private Subnet 배치
- [ ] 관리 접근 통제 (AWS: Session Manager / Azure: Bastion)

### 암호화 (2.7.x)
- [ ] 스토리지 암호화 (AWS: S3 SSE / Azure: Blob SSE)
- [ ] 볼륨 암호화 (AWS: EBS / Azure: Managed Disk)
- [ ] DB 암호화 (AWS: RDS / Azure: SQL TDE)
- [ ] TLS 1.2 이상 적용

### 백업/로그 (2.9.x)
- [ ] 백업 정책 설정 (AWS: Backup / Azure: Backup)
- [ ] 복구 테스트 수행 (RPO/RTO 검증)
- [ ] API 활동 로그 활성화 (AWS: CloudTrail / Azure: Activity Log)
- [ ] 스토리지 접근 로그 활성화
- [ ] 로그 보관 기간 설정 (최소 1년)
- [ ] 로그 위변조 방지 (AWS: S3 Object Lock / Azure: Immutable Storage)

### 모니터링 (2.10.x, 2.11.x)
- [ ] 위협 탐지 활성화 (AWS: GuardDuty / Azure: Defender for Cloud)
- [ ] 보안 대시보드 구성 (AWS: Security Hub / Azure: Defender for Cloud)
- [ ] 알림 설정 (AWS: SNS / Azure: Logic Apps)

---

## 참고 자료

### AWS
- [AWS Korea - K-ISMS 인증](https://aws.amazon.com/compliance/k-isms/)
- [AWS Korea - K-ISMS-P 규정준수팩](https://aws.amazon.com/ko/blogs/korea/aws-conformance-pack-for-k-isms-p-compliance/)

### Azure
- [Azure Compliance - Korea](https://learn.microsoft.com/ko-kr/azure/compliance/)
- [Azure Security Best Practices](https://learn.microsoft.com/ko-kr/azure/security/fundamentals/best-practices-and-patterns)
- [Microsoft Defender for Cloud](https://learn.microsoft.com/ko-kr/azure/defender-for-cloud/)

### 공통
- [SK쉴더스 - 클라우드 보안 가이드북](https://www.skshieldus.com/)
- [우아한형제들 - Hybrid-Cloud ISMS 인증](https://woowabros.github.io/security/2018/03/20/isms-certification.html)
- [금융보안원 - ISMS-P 인증](https://www.fsec.or.kr/bbs/107)
