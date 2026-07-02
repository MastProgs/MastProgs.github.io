class ResumeDocumentData {
  const ResumeDocumentData({
    required this.profile,
    required this.resumeSections,
    required this.skillSections,
    required this.experiences,
    required this.technicalSections,
    required this.projects,
  });

  final ResumeProfile profile;
  final List<DocumentSection> resumeSections;
  final List<SkillSectionData> skillSections;
  final List<ExperienceData> experiences;
  final List<TechnicalSectionData> technicalSections;
  final List<ProjectData> projects;
}

class ResumeProfile {
  const ResumeProfile({
    required this.name,
    required this.title,
    required this.phone,
    required this.email,
    required this.summary,
    required this.links,
  });

  final String name;
  final String title;
  final String phone;
  final String email;
  final List<String> summary;
  final List<LinkData> links;
}

class LinkData {
  const LinkData({required this.label, required this.url});

  final String label;
  final String url;
}

class DocumentSection {
  const DocumentSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class SkillSectionData {
  const SkillSectionData({required this.title, required this.skills});

  final String title;
  final List<SkillData> skills;
}

class SkillData {
  const SkillData({
    required this.name,
    required this.proficiency,
    required this.description,
  });

  final String name;
  final int proficiency;
  final String description;
}

class ExperienceData {
  const ExperienceData({
    required this.company,
    required this.period,
    required this.role,
    required this.highlights,
  });

  final String company;
  final String period;
  final String role;
  final List<String> highlights;
}

class TechnicalSectionData {
  const TechnicalSectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

class ProjectData {
  const ProjectData({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}

const resumeDocumentData = ResumeDocumentData(
  profile: ResumeProfile(
    name: '김형준',
    title: '서버 프로그래머',
    phone: '010-4140-0341',
    email: '_for@kakao.com',
    summary: [
      '게임 QA를 시작으로 2013년 게임업계에 첫 발을 딛고, 서버 프로그래머로 다양한 장르와 플랫폼의 게임 및 서비스를 경험했습니다.',
      'C++20, Go, Python, TypeScript, Flutter 등 여러 언어와 도구를 활용해 서버, 운영툴, 웹 서비스, 자동화 도구를 구현했습니다.',
      'AI, 빅데이터, 클라우드, NFT, 블록체인 등 새로운 기술을 실무 문제 해결과 생산성 향상에 연결하는 작업을 선호합니다.',
    ],
    links: [
      LinkData(label: 'GitHub', url: 'https://github.com/mastprogs'),
      LinkData(
        label: 'Naver Post',
        url:
            'https://m.blog.naver.com/PostList.naver?blogId=khjkhj2804&categoryNo=86',
      ),
    ],
  ),
  resumeSections: [
    DocumentSection(
      title: '학력',
      items: [
        '국민대학교 소프트웨어융합대학원 인공지능 학과 석사 졸업 (2021.03.01 ~ 2023.02.15)',
        '한국공학대학 게임공학과 4년제 학사 졸업 (2015.03.01 ~ 2018.02.09)',
        '대한민국 공군 병장 만기 전역 (2010.11.22 ~ 2012.11.23)',
      ],
    ),
    DocumentSection(
      title: '핵심 성향',
      items: [
        '새로운 기술 학습과 실무 적용을 통해 팀 생산성과 서비스 품질을 높이는 일을 선호합니다.',
        '기획, 클라이언트, 서버, 운영 환경 사이의 요구를 조율하며 유동적으로 설계를 개선하는 방식에 익숙합니다.',
        '단순 반복 구현보다 도전적인 문제 해결, 코드 리팩토링, 자동화, 개발 프로세스 개선에 강점이 있습니다.',
      ],
    ),
  ],
  skillSections: [
    SkillSectionData(
      title: 'AI',
      skills: [
        SkillData(
          name: 'Codex, Claude',
          proficiency: 3,
          description:
              '코드 작성, 리뷰, 문서화, 자동화 작업을 설계하고 다양한 오케스트레이션 기반 통합 구축 시스템을 만든 경험이 있습니다.',
        ),
        SkillData(
          name: 'OpenClaw, NanoClaw',
          proficiency: 3,
          description: '목적별 에이전트 구성과 반복 가능한 자동화 흐름을 구축한 경험이 있습니다.',
        ),
        SkillData(
          name: 'ADK, CrewAI',
          proficiency: 3,
          description: '역할 기반 에이전트 워크플로우로 코드 생성, 검증, 리포팅 과정을 연결한 경험이 있습니다.',
        ),
      ],
    ),
    SkillSectionData(
      title: '프로그래밍 언어 및 기술',
      skills: [
        SkillData(
          name: 'C++',
          proficiency: 3,
          description:
              'IOCP, Asio 서버 모델, C++20 최신화, MMORPG 서버 컨텐츠 구현 경험이 있습니다.',
        ),
        SkillData(
          name: 'Python',
          proficiency: 3,
          description: 'Fast API 서버 프레임워크, 자동화 툴, 데이터 분석 및 AI 모델 활용 경험이 있습니다.',
        ),
        SkillData(
          name: 'Go',
          proficiency: 3,
          description: '웹 서버, 로그 서버, ORM, 트랜잭션 보장 DBJob 구조를 구현한 경험이 있습니다.',
        ),
        SkillData(
          name: 'TypeScript',
          proficiency: 2,
          description:
              '운영툴, 게임 서버, TypeORM 기반 DBJob 및 Pagination 유틸 구현 경험이 있습니다.',
        ),
        SkillData(
          name: 'Flutter',
          proficiency: 3,
          description: '웹 프론트, 모바일 앱, 현재 웹 프로필 구현 및 서비스 경험이 있습니다.',
        ),
      ],
    ),
    SkillSectionData(
      title: '데이터베이스 및 인프라',
      skills: [
        SkillData(
          name: 'MSSQL, MySQL, Redis, MongoDB',
          proficiency: 3,
          description: '게임 서버 DB 설계, 프로시저, 캐싱, 랭킹, Pub/Sub, 로그 적재 경험이 있습니다.',
        ),
        SkillData(
          name: 'AWS, Azure, Firebase, Naver Cloud Platform',
          proficiency: 3,
          description:
              '서비스 배포, GameLift, RDS, S3, Lambda, 컴퓨팅/DB 서비스 구성 경험이 있습니다.',
        ),
        SkillData(
          name: 'Cloud Workers/Pages, GitHub Actions, Jenkins',
          proficiency: 3,
          description: '웹 배포, Android 빌드, CI/CD 파이프라인과 배포 스크립트 작성 경험이 있습니다.',
        ),
      ],
    ),
  ],
  experiences: [
    ExperienceData(
      company: '리치포켓',
      period: '2023.07 ~ 현재',
      role: '1인 창업 / 서비스 개발',
      highlights: [
        'MoneyCV 자동트레이딩, 주식마스터, 로또커스텀 등 웹/Android 서비스를 직접 기획, 개발, 배포했습니다.',
        'Flutter, Python, Go, Naver Cloud Platform, GitHub Actions 기반으로 서비스 운영 흐름을 구축했습니다.',
        '현재 한국콜마와 협력사로 함께 작업을 진행하며 웹 페이지 유지 보수, IT 인프라 관리, 기능 관리 구현을 담당하고 있습니다.',
      ],
    ),
    ExperienceData(
      company: '알레프리서치코리아',
      period: '2024.04 ~ 2024.07',
      role: '블록체인 코어 개발',
      highlights: [
        'Cosmos SDK 기반 블록체인 코어 개발 및 Sui Framework 기반 디파이 스테이킹 서비스 개발을 경험했습니다.',
      ],
    ),
    ExperienceData(
      company: '위메이드플러스',
      period: '2021.09 ~ 2023.06',
      role: '게임 서버 / 웹 서버 개발',
      highlights: [
        'NFT 소셜 플랫폼 Nallary 서버와 AWS 기반 서비스 환경을 구성했습니다.',
        '피싱 토네이도 챔피언십 C++20 포팅, Go 웹 서버, 로그 적재, dump 처리, Azure 클라우드 구성을 담당했습니다.',
        'Python Fast API 기반 서버 프레임워크와 다양한 코어 시스템, 채팅 소켓, 스케줄러, 코드 제너레이터를 구현했습니다.',
      ],
    ),
    ExperienceData(
      company: '조이시티',
      period: '2020.09 ~ 2021.04',
      role: '라이브 게임 서버 개발',
      highlights: [
        '프리스타일 라이브 서비스 리뉴얼, 컨텐츠 구현, 생산성 향상을 위한 개발망 런처와 아이템 지급 툴을 구현했습니다.',
      ],
    ),
    ExperienceData(
      company: '한빛소프트',
      period: '2020.02 ~ 2020.05',
      role: '게임 서버 개발',
      highlights: [
        'Gunslinger Stratos 프로젝트에서 AWS GameLift FlexMatch 연동과 웹 서버 매치메이킹 중개 구조를 구현했습니다.',
      ],
    ),
    ExperienceData(
      company: '모아이게임즈',
      period: '2017.08 ~ 2019.12',
      role: 'MMORPG 서버 개발',
      highlights: [
        'TRAHA 서버 시스템 설계 및 컨텐츠 구현, C# 운영툴 연동, MSSQL 프로시저 기반 라이브 서비스 작업을 담당했습니다.',
      ],
    ),
  ],
  technicalSections: [
    TechnicalSectionData(
      title: '자동화 및 개발 생산성',
      items: [
        'GitHub Actions 기반 코드리뷰 자동화와 빌드/배포 자동화를 구축했습니다.',
        '기획 xlsx 파일을 기반으로 서버 데이터 스크립트와 코드를 생성하는 Code Generator를 구현했습니다.',
        '개발망 클라이언트 실행 런처, 아이템 지급 툴, C# WPF 부하테스트 툴 등 반복 작업을 줄이는 도구를 만들었습니다.',
      ],
    ),
    TechnicalSectionData(
      title: '서버 아키텍처 및 데이터 처리',
      items: [
        'C++20 포팅, 문자열 인코딩 핸들러, Redis 핸들러, 날짜/시간 통합 관리 유틸을 구현했습니다.',
        'Go TypeORM, TypeScript DBJob, Pagination 래퍼 등 DB 접근과 트랜잭션 처리를 단순화하는 구조를 설계했습니다.',
        '게임 서버 로그를 JSON으로 수집해 Log 서버에서 DB 테이블 구조에 맞춰 검증/적재하는 파이프라인을 구현했습니다.',
      ],
    ),
    TechnicalSectionData(
      title: '클라우드 및 서비스 운영',
      items: [
        'AWS GameLift FlexMatch를 활용해 로비 서버, 웹 서버, 데디케이티드 서버 간 매치메이킹 흐름을 구현했습니다.',
        'AWS, Azure, Naver Cloud Platform 기반 서비스 배포와 운영 환경 구성을 경험했습니다.',
        'Cloudflare Workers/Pages와 GitHub Actions로 웹 프론트 및 Android 릴리즈 자동화를 구성했습니다.',
      ],
    ),
  ],
  projects: [
    ProjectData(
      title: '게임 개발부터 QA까지 자동화 프로세스 구축',
      description:
          'nanoclaw 기반으로 여러 AI 모델을 협업시켜 게임 개발부터 QA까지 자동화 프로세스를 구축했습니다.',
      url: 'https://blog.naver.com/khjkhj2804/224241614658',
    ),
    ProjectData(
      title: 'SNS 자동 글 쓰기',
      description: '실시간 트렌드를 기반으로 내용을 요약하여 자동으로 SNS에 글을 쓰는 프로세스를 구축했습니다.',
      url: 'https://naver.me/5bV09fiw',
    ),
    ProjectData(
      title: '분류 모델 AI 차트 분석',
      description: '코인 차트를 분류 모델로 구분하고 예측하는 대학원 졸업 논문 연구 프로젝트입니다.',
      url: 'http://ggram.ipdisk.co.kr/',
    ),
    ProjectData(
      title: '애니메이션 추천 시스템',
      description: '평가 관계도와 데이터 분석을 활용해 선택 애니메이션에 맞는 추천 결과를 제공하는 시스템입니다.',
      url: 'https://naver.me/51YeJXCy',
    ),
  ],
);
