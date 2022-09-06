<template>
  <v-app>
    
    <v-navigation-drawer
      app
      dark
      expand-on-hover
      permanent
    >

      <v-list-item class="px-2">
        <v-list-item-avatar rounded>
          <v-img src="./assets/myface.png"/>
          <!-- <v-img src="https://mastprogs.github.io/myintroduce/photo/myface.png"/> -->
        </v-list-item-avatar>
        
        <v-list-item-content>
          <v-list-item-title class="title">
            김형준
          </v-list-item-title>

          <v-list-item-subtitle>
            게임 서버 프로그래머
          </v-list-item-subtitle>
        </v-list-item-content>
      </v-list-item>

      <v-divider></v-divider>

      <v-list-item-group
        dark
      >

        <v-list
          dense
          nav
        >
          <v-list-item
            v-for="(item, index) in m_navigation_list_item"
            :key="index"
            link
            v-on:click="NavButtonClicked(index)"
          >
          
            <v-list-item-icon>
              <v-icon>{{ item.icon }}</v-icon>
            </v-list-item-icon>
            <v-list-item-content>
              <v-list-item-title>{{ item.namedtext }}</v-list-item-title>
            </v-list-item-content>

          </v-list-item>
        </v-list>

      </v-list-item-group>
    </v-navigation-drawer>

    <v-app-bar app dark dense>
      <v-layout align-center justify-center>
        <p>최신 업데이트 날짜 : 2022-09-06</p>
      </v-layout>
    </v-app-bar>

    <v-main>
      <v-content fluid>

        <div v-if="m_navVal === 0">
          <Profile/>
        </div>
        
        <div v-if="m_navVal === 1">
          <TimeLine/>
        </div>
        
        <div v-if="m_navVal === 2">
          <MyWork/>
        </div>
        
        <div v-if="m_navVal === 3">
          <MyPrivateProjects/>
        </div>
        
        <div v-if="m_navVal === 4">
          <h1>이력서 다운로드(공사중)</h1>
        </div>
      </v-content>
    </v-main>


  </v-app>
</template>

<script>
import Profile from './components/Profile';
import TimeLine from './components/TimeLine';
import MyWork from './components/MyWork';
import MyPrivateProjects from './components/MyPrivateProjects';

export default {
  name: 'App',

  components: {
    Profile,
    TimeLine,
    MyWork,
    MyPrivateProjects,
  },

  data: () => ({
    m_navVal: 0,

    m_navigation_list_item: [
      { namedtext: '자기 소개', icon: 'mdi-badge-account-horizontal'},
      { namedtext: '회사 경력', icon: 'mdi-briefcase'},
      { namedtext: '과거 작업내역', icon: 'mdi-apps'},
      { namedtext: '개인 프로젝트', icon: 'mdi-apps-box'},
      { namedtext: '이력서 다운로드', icon: 'mdi-inbox-arrow-down'},
    ],
  }),

  methods: {
    NavButtonClicked: function (stateParam) {
      this.m_navVal = stateParam
    }
  },

  computed:{
    
  },
};
</script>
