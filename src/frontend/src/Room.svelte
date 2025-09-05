<script>
  import { onMount, onDestroy } from 'svelte';
  
  export let roomId;
  
  let room = null;
  let loading = false;
  let error = null;
  let eventSource = null;
  let evolutionLog = [];
  
  const API_BASE = 'http://localhost:8080/api';
  
  const OPERATORS = [
    'もっとホラー',
    'もっとロマンス',
    'もっとSF',
    'もっとコメディ',
    'もっと詩的に',
    'もっとセリフを',
    'もっと舞台を変える',
    'もっとキャラを増やす',
    'もっと混沌',
    'もっとスピード感を'
  ];
  
  async function loadRoom() {
    loading = true;
    error = null;
    try {
      const response = await fetch(`${API_BASE}/rooms/${roomId}`);
      if (!response.ok) throw new Error('Failed to load room');
      room = await response.json();
    } catch (err) {
      error = err.message;
    } finally {
      loading = false;
    }
  }
  
  async function nudge(operator) {
    error = null;
    try {
      const response = await fetch(`${API_BASE}/rooms/${roomId}/nudge`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          operator,
          actor: 'user' 
        })
      });
      
      if (!response.ok) throw new Error('Failed to nudge');
      
      const result = await response.json();
      room = result.room;
      
      // 進化ログに追加
      evolutionLog = [{
        operator,
        timestamp: new Date(),
        generation: room.generation
      }, ...evolutionLog].slice(0, 10);
      
    } catch (err) {
      error = err.message;
    }
  }
  
  function connectEventSource() {
    eventSource = new EventSource(`${API_BASE}/rooms/${roomId}/events`);
    
    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      room = data.room;
      
      if (data.nudge) {
        evolutionLog = [{
          operator: data.nudge.operator,
          actor: data.nudge.actor,
          timestamp: new Date(),
          generation: room.generation
        }, ...evolutionLog].slice(0, 10);
      }
    };
    
    eventSource.onerror = (err) => {
      console.error('EventSource error:', err);
    };
  }
  
  onMount(() => {
    loadRoom();
    // SSE接続は後で有効化
    // connectEventSource();
  });
  
  onDestroy(() => {
    if (eventSource) {
      eventSource.close();
    }
  });
</script>

<div class="room">
  <div class="room-header">
    <h2>ルーム {roomId ? roomId.slice(0, 8) : ''}</h2>
    {#if room}
      <span class="generation">第{room.generation}世代</span>
    {/if}
  </div>
  
  {#if loading}
    <div class="loading">読み込み中...</div>
  {:else if error}
    <div class="error">{error}</div>
  {:else if room}
    <div class="content">
      <div class="text-display">
        <p>{room.current_text}</p>
      </div>
      
      <div class="controls">
        <h3>物語を進化させる</h3>
        <div class="operator-buttons">
          {#each OPERATORS as operator}
            <button 
              class="operator-btn"
              on:click={() => nudge(operator)}
            >
              {operator}
            </button>
          {/each}
        </div>
      </div>
      
      <div class="evolution-log">
        <h3>進化ログ</h3>
        <div class="log-entries">
          {#each evolutionLog as entry}
            <div class="log-entry">
              <span class="log-time">
                {entry.timestamp.toLocaleTimeString()}
              </span>
              <span class="log-operator">{entry.operator}</span>
              <span class="log-generation">→ 第{entry.generation}世代</span>
            </div>
          {/each}
          
          {#if evolutionLog.length === 0}
            <div class="no-logs">まだ進化していません</div>
          {/if}
        </div>
      </div>
    </div>
  {/if}
</div>

<style>
  .room {
    padding: 1.5rem;
  }
  
  .room-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-bottom: 1rem;
    border-bottom: 2px solid #f0f0f0;
    margin-bottom: 1.5rem;
  }
  
  .room-header h2 {
    margin: 0;
    font-size: 1.3rem;
    color: #333;
  }
  
  .generation {
    background: #667eea;
    color: white;
    padding: 0.3rem 0.8rem;
    border-radius: 20px;
    font-size: 0.9rem;
    font-weight: 600;
  }
  
  .text-display {
    background: #f8f9fa;
    padding: 2rem;
    border-radius: 8px;
    margin-bottom: 2rem;
    min-height: 200px;
    line-height: 1.8;
  }
  
  .text-display p {
    font-size: 1.1rem;
    color: #2c3e50;
    margin: 0;
  }
  
  .controls {
    margin-bottom: 2rem;
  }
  
  .controls h3 {
    color: #666;
    font-size: 1rem;
    margin-bottom: 1rem;
  }
  
  .operator-buttons {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 0.5rem;
  }
  
  .operator-btn {
    background: white;
    border: 2px solid #e0e0e0;
    color: #333;
    padding: 0.6rem 1rem;
    border-radius: 8px;
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.3s;
  }
  
  .operator-btn:hover {
    background: #667eea;
    color: white;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
  }
  
  .evolution-log {
    border-top: 2px solid #f0f0f0;
    padding-top: 1.5rem;
  }
  
  .evolution-log h3 {
    color: #666;
    font-size: 1rem;
    margin-bottom: 1rem;
  }
  
  .log-entries {
    max-height: 200px;
    overflow-y: auto;
  }
  
  .log-entry {
    display: flex;
    gap: 0.5rem;
    padding: 0.5rem;
    border-left: 3px solid #667eea;
    margin-bottom: 0.5rem;
    background: #f8f9fa;
    font-size: 0.85rem;
  }
  
  .log-time {
    color: #999;
  }
  
  .log-operator {
    font-weight: 600;
    color: #667eea;
  }
  
  .log-generation {
    color: #666;
  }
  
  .no-logs {
    color: #999;
    text-align: center;
    padding: 1rem;
  }
  
  .loading, .error {
    text-align: center;
    padding: 2rem;
  }
  
  .error {
    color: #ff4757;
  }
</style>