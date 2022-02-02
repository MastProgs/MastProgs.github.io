<template>
    <v-container>

        <br><br>
        <v-divider></v-divider>
        <br><br>

        <v-row justify="space-around">
            <v-card width="100%">
                <!--v-carousel>
                    <v-carousel-item src="../assets/joycity.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/freestyle_1.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                </v-carousel-->
                <v-app-bar
                    flat
                    color="rgba(0, 0, 0, 0)"
                >
                    <v-avatar size="50">
                        <v-img src="../assets/wemade.png"/>
                    </v-avatar>

                    <v-toolbar-title class="title ml-4">Wemade Plus</v-toolbar-title>
                </v-app-bar>
                
                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        프로젝트 정보
                    </div>
                    <div class="ml-8 mb-2">
                        <v-simple-table class="text-left">
                            <thead>
                                <tr>
                                    <th>분류</th>
                                    <th>설명</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th>프로젝트 이름</th>
                                    <th>Nallary</th>
                                </tr>
                                <tr>
                                    <th>프로젝트 장르</th>
                                    <th>Community SNS App, NFT Trading Platform</th>
                                </tr>
                                <tr>
                                    <th>출시 플랫폼</th>
                                    <th>Mobile</th>
                                </tr>
                                <tr>
                                    <th>그래픽 뷰</th>
                                    <th>Web Gallary, Ingame = 3D Full View</th>
                                </tr>
                            </tbody>
                        </v-simple-table>
                    </div>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        사용 기술
                    </div>
                    <v-row class="ml-8">
                        <v-img class="mb-2" src="../assets/typescript.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/sql.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/redis.jpg" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/aws.png" max-width="50" max-height="50"/>
                    </v-row>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        타임라인
                    </div>

                    <v-timeline
                        align-top
                        dense
                    >
                        <v-timeline-item
                        v-for="message in cp_wemadePlus"
                        :key="message.time"
                        :color="message.color"
                        small
                        >
                        <div>
                            <div class="font-weight-normal">
                            <strong>{{ message.time }} - {{ message.title }}</strong>
                            </div>
                            <div>{{ message.description }}</div>
                        </div>
                        </v-timeline-item>
                    </v-timeline>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">설명</div>
                    <v-textarea
                        class="ml-8 mb-2"
                        filled
                        auto-grow
                        readonly
                        value="NFT 트레이딩 관련 게임 및 모바일 앱 개발 진행중입니다"
                    />
                </v-card-text>
            </v-card>
        </v-row>

        <br><br>
        <v-divider></v-divider>
        <br><br>

        <v-row justify="space-around">
            <v-card width="100%">
                <v-carousel>
                    <v-carousel-item src="../assets/joycity.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/freestyle_1.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                </v-carousel>
                <v-app-bar
                    flat
                    color="rgba(0, 0, 0, 0)"
                >
                    <v-avatar size="50">
                        <v-img src="../assets/freestyle.png"/>
                    </v-avatar>

                    <v-toolbar-title class="title ml-4">Joycity</v-toolbar-title>
                </v-app-bar>
                
                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        프로젝트 정보
                    </div>
                    <div class="ml-8 mb-2">
                        <v-simple-table class="text-left">
                            <thead>
                                <tr>
                                    <th>분류</th>
                                    <th>설명</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th>게임 이름</th>
                                    <th>Free Style 1</th>
                                </tr>
                                <tr>
                                    <th>게임 장르</th>
                                    <th>Arcade</th>
                                </tr>
                                <tr>
                                    <th>출시 플랫폼</th>
                                    <th>Desktop PC</th>
                                </tr>
                                <tr>
                                    <th>그래픽 뷰</th>
                                    <th>3D Top View</th>
                                </tr>
                            </tbody>
                        </v-simple-table>
                    </div>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        사용 기술
                    </div>
                    <v-row class="ml-8">
                        <v-img class="mb-2" src="../assets/cpp.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/sql.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/windows.png" max-width="50" max-height="50"/>
                    </v-row>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        타임라인
                    </div>

                    <v-timeline
                        align-top
                        dense
                    >
                        <v-timeline-item
                        v-for="message in cp_joycity"
                        :key="message.time"
                        :color="message.color"
                        small
                        >
                        <div>
                            <div class="font-weight-normal">
                            <strong>{{ message.time }} - {{ message.title }}</strong>
                            </div>
                            <div>{{ message.description }}</div>
                        </div>
                        </v-timeline-item>
                    </v-timeline>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">설명</div>
                    <v-textarea
                        class="ml-8 mb-2"
                        filled
                        auto-grow
                        readonly
                        value="게임 전체적으로 급하게 리뉴얼 작업을 해야하다보니 일손이 필요하다고 하여, 제의를 받아 입사를 진행했던 회사입니다. 입사하자마자 업무량이 몰려있는 리뉴얼 작업을 담당했었고, 그와 함께 필요한 각종 이벤트 및 컨텐츠 작업들도 같이 작업하며 리뉴얼 업무를 했던 회사입니다. 하지만, 대학원과 병행하기에는 야근이 너무 많았었고, 어느정도 큰 업무 처리들은 잘 마무리 되었다고 판단하여 8개월 즈음에 퇴사를 진행하게 되었습니다."
                    />
                </v-card-text>
            </v-card>
        </v-row>

        <br><br>
        <v-divider></v-divider>
        <br><br>

        <v-row justify="space-around">
            <v-card width="100%">
                <v-carousel>
                    <v-carousel-item src="../assets/hnbit2.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/square.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/gunslinger_stratos.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/company_unreal.png" reverse-transition="fade-transition" transition="fade-transition"/>
                </v-carousel>
                <v-app-bar
                    flat
                    color="rgba(0, 0, 0, 0)"
                >
                    <v-avatar size="50">
                        <v-img src="../assets/gunsl.png"/>
                    </v-avatar>

                    <v-toolbar-title class="title ml-4">HanbitSoft</v-toolbar-title>
                </v-app-bar>
                
                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        프로젝트 정보
                    </div>
                    <div class="ml-8 mb-2">
                        <v-simple-table class="text-left">
                            <thead>
                                <tr>
                                    <th>분류</th>
                                    <th>설명</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th>게임 이름</th>
                                    <th>Gunslinger Stratos</th>
                                </tr>
                                <tr>
                                    <th>게임 장르</th>
                                    <th>TPS</th>
                                </tr>
                                <tr>
                                    <th>출시 플랫폼</th>
                                    <th>Desktop PC</th>
                                </tr>
                                <tr>
                                    <th>그래픽 뷰</th>
                                    <th>3D Full View</th>
                                </tr>
                            </tbody>
                        </v-simple-table>
                    </div>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        사용 기술
                    </div>
                    <v-row class="ml-8">
                        <v-img class="mb-2" src="../assets/cpp.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/js.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/sql.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/aws.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/ueicon.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/centos.jpg" max-width="50" max-height="50"/>
                    </v-row>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        타임라인
                    </div>

                    <v-timeline
                        align-top
                        dense
                    >
                        <v-timeline-item
                        v-for="message in cp_hanbit"
                        :key="message.time"
                        :color="message.color"
                        small
                        >
                        <div>
                            <div class="font-weight-normal">
                            <strong>{{ message.time }} - {{ message.title }}</strong>
                            </div>
                            <div>{{ message.description }}</div>
                        </div>
                        </v-timeline-item>
                    </v-timeline>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">설명</div>
                    <v-textarea
                        class="ml-8 mb-2"
                        filled
                        auto-grow
                        readonly
                        value="입사하고 나서 얼마 있지 않아 몸이 금방 아프게되어 아쉽게 퇴사하게 된 회사입니다. 해당 프로젝트는 일본의 글로벌 기업인 Square Enix 와 함께 협업으로 진행되는 글로벌 프로젝트였습니다. 프로젝트가 약 1년정도 진행이 되고 있던 상황에 합류하였으며, TPS 게임 장르의 게임이었습니다. 언리얼의 데디케이티드 서버 + 웹 서버를 활용하여 게임이 제작되었으며, 제가 주로 담당했던 업무는 AWS의 GameLift 기능 중 Flexmatch 라는 매치메이킹 관련 기능을 웹 서버와 데디케이티드 서버에 각각 구현하는 역할이 주 업무였습니다. 기타 업무는 라이브 서비스를 위한 운영툴에서 정보 조회 기능을 구현하는 역할도 담당하였습니다. 몸이 아파서 퇴사를 고민하던 시점에 함께 계속 일을 했으면 좋겠다는 요청을 주시며 아쉬움을 표하셨지만, 저 스스로도 일단 몸의 휴식이 최우선이라고 생각하여 원래 계획대로 나오게 되었습니다."
                    />
                </v-card-text>
            </v-card>
        </v-row>

        <br><br>
        <v-divider></v-divider>
        <br><br>

        <v-row justify="space-around">
            <v-card width="100%">
                <v-carousel>
                    <v-carousel-item src="../assets/company_nexon_moai.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/company_traha.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/company_traha2.jpg" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/company_traha3.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/company_unreal.png" reverse-transition="fade-transition" transition="fade-transition"/>
                    <v-carousel-item src="../assets/traha_play.webp" reverse-transition="fade-transition" transition="fade-transition"/>
                </v-carousel>
                <v-app-bar
                    flat
                    color="rgba(0, 0, 0, 0)"
                >
                    <v-avatar size="50">
                        <v-img src="../assets/traha_title.webp"/>
                    </v-avatar>

                    <v-toolbar-title class="title ml-4">MOAIGAMES</v-toolbar-title>

                    <v-spacer></v-spacer>
                </v-app-bar>
                
                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        프로젝트 정보
                    </div>
                    <div class="ml-8 mb-2">
                        <v-simple-table class="text-left">
                            <thead>
                                <tr>
                                    <th>분류</th>
                                    <th>설명</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <th>게임 이름</th>
                                    <th>TRAHA</th>
                                </tr>
                                <tr>
                                    <th>게임 장르</th>
                                    <th>MMORPG</th>
                                </tr>
                                <tr>
                                    <th>출시 플랫폼</th>
                                    <th>Mobile</th>
                                </tr>
                                <tr>
                                    <th>그래픽 뷰</th>
                                    <th>3D Full View</th>
                                </tr>
                            </tbody>
                        </v-simple-table>
                    </div>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        사용 기술
                    </div>
                    <v-row class="ml-8">
                        <v-img class="mb-2" src="../assets/cpp.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/cpppp.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/sql.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/azure.jpg" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/ueicon.png" max-width="50" max-height="50"/>
                        <v-img class="ml-8 mb-2" src="../assets/windows.png" max-width="50" max-height="50"/>
                    </v-row>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">
                        타임라인
                    </div>

                    <v-timeline
                        align-top
                        dense
                    >
                        <v-timeline-item
                        v-for="message in cp_moai"
                        :key="message.time"
                        :color="message.color"
                        small
                        >
                        <div>
                            <div class="font-weight-normal">
                            <strong>{{ message.time }} - {{ message.title }}</strong>
                            </div>
                            <div>{{ message.description }}</div>
                        </div>
                        </v-timeline-item>
                    </v-timeline>
                </v-card-text>

                <v-card-text>
                    <div class="font-weight-bold ml-8 mb-2">설명</div>
                    <v-textarea
                        class="ml-8 mb-2"
                        filled
                        auto-grow
                        readonly
                        value="트라하 개발 초창기에 입사하여 서버의 시스템 설계 및 컨텐츠 관련 작업을 주로 진행하였습니다. 거의 대부분 C++로 작업을 진행하였고, 구현했던 컨텐츠를 기반으로, 넥슨 사에서 제공되는 운영툴 양식에 맞게 C#으로 컨텐츠 내용을 연동하여 라이브 서비스에서 활용할 수 있도록 하는 작업을 담당하였습니다. 핵심 코어 코드들은 입사하기 전에 구현이 되어 있었고, 기존에 존재하는 코어 시스템 위에 이를 활용한 새 컨텐츠를 올리는 형태의 작업이 많았습니다. DB의 경우 MSSQL을 활용했었고, 프로시저를 미리 구현하여 필요한 때에 프로시저를 활용하는 형태로 사용하였습니다."
                    />
                </v-card-text>
            </v-card>
        </v-row>
        <!--
        <v-timeline>
            <v-timeline-item
                v-for="(d, i) in timeline_data"
                :key="i"
                :color="d.color"
                small
                dense
            >
                <template v-slot:opposite>
                    <span
                    :class="`headline font-weight-bold ${d.color}--text`"
                    v-text="d.date"
                    ></span>
                </template>

                <div class="py-4">
                    <v-card class="elevation-2" shaped>
                        <v-card-title :class="`headline font-weight-light mb-4 ${d.color}--text`">{{ d.company }}</v-card-title>
                        <v-card-subtitle>aaaaa</v-card-subtitle>
                        <v-card-text>{{ d.description }}</v-card-text>
                    </v-card>

                </div>

            </v-timeline-item>
        </v-timeline>
        -->

    </v-container>
</template>

<script>
  export default {
    name: 'TimeLine',

    mounted() {

    },

    data: () => ({
        timeline_data: [
            {
                company: "위메이드 플러스",
                description: "abcd",
                color: "blue",
                date:"2021.09.06 ~ XX.XX.XX"
            },
            {
                company: "조이시티",
                description: "abcd",
                color: "orange",
                date:"2020.09.07 ~ 2021.04.30"
            },
            {
                company: "한빛소프트",
                description: "abcd",
                color: "red",
                date:"2020.02.03 - 2020.05.01"
            },
            {
                company: "모아이게임즈",
                description: "abcd",
                color: "blue",
                date:"2017.08.07 - 2019.12.13",
                imgsrc: [
                    "../assets/company_nexon_moai.png",
                    "../assets/company_traha.jpg",
                    "../assets/company_traha2.jpg",
                    "../assets/company_traha3.png",
                    "../assets/company_unreal.png",
                ]
            },
        ],

        cp_moai: [
            {
                title: "퇴사",
                description: "회사의 경영난과 새로운 개발 환경을 경험하기 위하여 퇴사",
                time: "2019.12.13",
                color: "red",
            },
            {
                title: "한국 라이브 서비스 런칭",
                description: "개발 중이던 게임을 라이브 서비스 런칭 진행",
                time: "2018.04.18",
                color: "blue",
            },
            {
                title: "입사",
                description: "모아이게임즈 트라하 서버 프로그래머로 입사",
                time: "2017.08.07",
                color: "red",
            },
        ],
        
        cp_hanbit: [
            {
                title: "퇴사",
                description: "건강 악화로 몸 회복을 위해 원치않게 퇴사",
                time: "2020.05.01",
                color: "blue",
            },
            {
                title: "입사",
                description: "한빛소프트 서버 프로그래머로 입사",
                time: "2020.02.03",
                color: "red",
            },
        ],

        cp_joycity: [
            {
                title: "퇴사",
                description: "인공지능 대학원 학업 집중을 위해 퇴사",
                time: "2021.04.13",
                color: "blue",
            },
            {
                title: "입사",
                description: "조이시티 서버 프로그래머로 입사",
                time: "2020.09.07",
                color: "red",
            },
        ],
        
        cp_wemadePlus: [
            {
                title: "입사",
                description: "위메이드 플러스 서버 프로그래머로 입사",
                time: "2021.09.06",
                color: "red",
            },
        ],
    }),

    methods: {

    },
  }
</script>

<style scoped>

</style>