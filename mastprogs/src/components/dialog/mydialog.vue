<!-- 사용법 : https://velog.io/@roro/Vue-slot%EC%9D%84-%EC%9D%B4%EC%9A%A9%ED%95%98%EC%97%AC-dialog-component-%EB%A7%8C%EB%93%A4%EA%B8%B0with-vuetify -->

<template>
  <v-card>
    <v-card-title>
        {{ headerTitle }}
    </v-card-title>
    <v-card-text>
      <slot name="body">
          {{ defaultBodyContent }}
      </slot>
    </v-card-text>
    <v-card-actions class="justify-end mr-2 pb-4">
        <v-btn 
            color="amber"
            dark
            rounded
            small
            @click="$emit('hide')"
        >
            {{ footerHideTitle }}
        </v-btn>
        <template v-if="footerSubmit">
            <v-btn
                color="success"
                rounded
                small
                @click="$emit('submit')"
            >
                {{ footerSubmitTitle }}
            </v-btn>
        </template>
    </v-card-actions>
  </v-card>
</template>

<script>
  export default {
    name: 'MyDialog',
    props: {
      footerSubmit: {
        type: Boolean,
        default: true,
      },
      headerTitle: {
        type: String,
        default: '제목',
      },
      footerSubmitTitle: {
        type: String,
        default: '저장',
      },
    },
  }
</script>