<template>
  <div class="container">
    <!-- This is an HTML comment in Vue -->
    <h1>{{ title }}</h1>
    <button @click="increment">Count: {{ count }}</button>
  </div>
</template>

<script>
export default {
  data() {
    return {
      title: 'Vue Test',
      count: 0
    }
  },
  methods: {
    increment() {
      this.count++
    }
  }
}
</script>

<style scoped>
.container {
  padding: 20px;
}
</style>
