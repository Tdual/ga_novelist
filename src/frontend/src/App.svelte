<script>
  import { onMount } from 'svelte';
  import Room from './Room.svelte';

  let rooms = [];
  let selectedRoomId = null;
  let loading = false;
  let error = null;

  const API_BASE = 'http://localhost:8080/api';

  async function createRoom() {
    loading = true;
    error = null;
    try {
      const response = await fetch(`${API_BASE}/rooms`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      if (!response.ok) throw new Error('Failed to create room');
      
      const room = await response.json();
      rooms = [...rooms, room];
      selectedRoomId = room.id;
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }

  async function loadRooms() {
    // 後で実装: 既存のルーム一覧を取得
  }

  onMount(() => {
    // 初期ルームを4つ作成
    for (let i = 0; i < 4; i++) {
      createRoom();
    }
  });
</script>

<main>
  <header>
    <h1>📖 即時進化型小説サービス</h1>
    <p>4つのルームが同じ初期文から始まり、あなたのクリックで進化します</p>
  </header>

  {#if error}
    <div class="error">{error}</div>
  {/if}

  <div class="rooms-container">
    {#each rooms as room}
      <div class="room-card" class:selected={selectedRoomId === room.id}>
        <Room roomId={room.id} />
      </div>
    {/each}
    
    {#if rooms.length === 0 && loading}
      <div class="loading">ルームを作成中...</div>
    {/if}
  </div>
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: 'Noto Sans JP', sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
  }

  main {
    padding: 2rem;
    max-width: 1400px;
    margin: 0 auto;
  }

  header {
    text-align: center;
    color: white;
    margin-bottom: 2rem;
  }

  h1 {
    font-size: 2.5rem;
    margin-bottom: 0.5rem;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
  }

  header p {
    font-size: 1.1rem;
    opacity: 0.95;
  }

  .rooms-container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(600px, 1fr));
    gap: 2rem;
  }

  .room-card {
    background: white;
    border-radius: 12px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    overflow: hidden;
    transition: transform 0.3s;
  }

  .room-card:hover {
    transform: translateY(-5px);
  }

  .room-card.selected {
    box-shadow: 0 10px 40px rgba(0,0,0,0.3), 0 0 0 3px #667eea;
  }

  .error {
    background: #ff4757;
    color: white;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
    text-align: center;
  }

  .loading {
    grid-column: 1 / -1;
    text-align: center;
    color: white;
    font-size: 1.2rem;
    padding: 2rem;
  }
</style>