package services

import (
	"context"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type closeNotifyRecorder struct {
	*httptest.ResponseRecorder
	closed chan bool
}

func (r *closeNotifyRecorder) CloseNotify() <-chan bool {
	return r.closed
}

func TestNewSSEService(t *testing.T) {
	s := NewSSEService()
	require.NotNil(t, s)
	assert.Empty(t, s.clients)
}

func TestHandleSSESendsInitialCommentAndHeartbeat(t *testing.T) {
	gin.SetMode(gin.TestMode)
	s := NewSSEService()
	s.heartbeatInterval = time.Millisecond

	recorder := &closeNotifyRecorder{
		ResponseRecorder: httptest.NewRecorder(),
		closed:           make(chan bool),
	}
	c, _ := gin.CreateTestContext(recorder)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()
	c.Request = httptest.NewRequest("GET", "/events", nil).WithContext(ctx)

	s.HandleSSE(c)

	assert.Equal(t, "text/event-stream", recorder.Header().Get("Content-Type"))
	assert.Equal(t, "no", recorder.Header().Get("X-Accel-Buffering"))
	body := recorder.Body.String()
	assert.True(t, strings.HasPrefix(body, ": connected\n\n"))
	assert.Contains(t, body, ": ping\n\n")
}

func TestAddClient(t *testing.T) {
	s := NewSSEService()
	client := &SSEClient{ID: "client-1", Events: make(chan SSEEvent, 10)}
	s.AddClient(client)

	assert.Len(t, s.clients, 1)
	assert.Equal(t, client, s.clients["client-1"])
}

func TestRemoveClient(t *testing.T) {
	s := NewSSEService()
	client := &SSEClient{ID: "client-1", Events: make(chan SSEEvent, 10)}
	s.AddClient(client)
	s.RemoveClient("client-1")

	assert.Empty(t, s.clients)
}

func TestRemoveNonExistentClient(t *testing.T) {
	s := NewSSEService()
	s.RemoveClient("nonexistent")
	assert.Empty(t, s.clients)
}

func TestBroadcastDeliversToAllClients(t *testing.T) {
	s := NewSSEService()
	c1 := &SSEClient{ID: "c1", Events: make(chan SSEEvent, 10)}
	c2 := &SSEClient{ID: "c2", Events: make(chan SSEEvent, 10)}
	s.AddClient(c1)
	s.AddClient(c2)

	s.Broadcast("test-event", map[string]string{"key": "value"})

	select {
	case evt := <-c1.Events:
		assert.Equal(t, "test-event", evt.Event)
	case <-time.After(time.Second):
		t.Fatal("c1 did not receive event")
	}

	select {
	case evt := <-c2.Events:
		assert.Equal(t, "test-event", evt.Event)
	case <-time.After(time.Second):
		t.Fatal("c2 did not receive event")
	}
}

func TestBroadcastDoesNotBlockOnFullChannel(t *testing.T) {
	s := NewSSEService()
	client := &SSEClient{ID: "c1", Events: make(chan SSEEvent, 1)}
	s.AddClient(client)

	client.Events <- SSEEvent{Event: "blocking"}
	s.Broadcast("overflow", nil)

	assert.Len(t, client.Events, 1)
}

func TestEmitCallsBroadcast(t *testing.T) {
	s := NewSSEService()
	client := &SSEClient{ID: "c1", Events: make(chan SSEEvent, 10)}
	s.AddClient(client)

	s.Emit("emit-event", "data")

	select {
	case evt := <-client.Events:
		assert.Equal(t, "emit-event", evt.Event)
		assert.Equal(t, "data", evt.Data)
	case <-time.After(time.Second):
		t.Fatal("client did not receive event")
	}
}

func TestConcurrentAddAndBroadcast(t *testing.T) {
	s := NewSSEService()
	done := make(chan bool)

	go func() {
		for i := 0; i < 100; i++ {
			client := &SSEClient{
				ID:     "c1",
				Events: make(chan SSEEvent, 10),
			}
			s.AddClient(client)
			s.RemoveClient("c1")
		}
		done <- true
	}()

	go func() {
		for i := 0; i < 100; i++ {
			s.Broadcast("concurrent", nil)
		}
		done <- true
	}()

	<-done
	<-done
}
