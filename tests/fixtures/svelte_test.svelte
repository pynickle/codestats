<script>
  // This is a JavaScript comment in Svelte
  let count = 0;
  let title = 'Svelte Test';

  function increment() {
    count++;
  }
</script>

<!-- This is an HTML comment in Svelte -->
<div class="container">
  <h1>{title}</h1>
  <button on:click={increment}>
    Count: {count}
  </button>
</div>

<style>
  .container {
    padding: 20px;
  }
</style>
