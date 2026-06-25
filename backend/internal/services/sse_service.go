package services

import (
	"fmt"
	"io"
	"sync"

	"github.com/gin-gonic/gin"
)

type SSEEvent struct {
	Event string      `json:"event"`
	Data  interface{} `json:"data"`
}

type SSEClient struct {
	ID     string
	Events chan SSEEvent
}

type SSEService struct {
	mu      sync.RWMutex
	clients map[string]*SSEClient
}

func NewSSEService() *SSEService {
	return &SSEService{
		clients: make(map[string]*SSEClient),
	}
}

func (s *SSEService) AddClient(client *SSEClient) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.clients[client.ID] = client
}

func (s *SSEService) RemoveClient(id string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.clients, id)
}

func (s *SSEService) Broadcast(event string, data interface{}) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	msg := SSEEvent{Event: event, Data: data}
	for _, client := range s.clients {
		select {
		case client.Events <- msg:
		default:
		}
	}
}

func (s *SSEService) HandleSSE(c *gin.Context) {
	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("Access-Control-Allow-Origin", "*")

	client := &SSEClient{
		ID:     fmt.Sprintf("client_%d", len(s.clients)+1),
		Events: make(chan SSEEvent, 10),
	}
	s.AddClient(client)

	defer s.RemoveClient(client.ID)

	c.Stream(func(w io.Writer) bool {
		select {
		case evt, ok := <-client.Events:
			if !ok {
				return false
			}
			c.SSEvent(evt.Event, evt.Data)
			return true
		case <-c.Request.Context().Done():
			return false
		}
	})
}

func (s *SSEService) Emit(event string, data interface{}) {
	s.Broadcast(event, data)
}
