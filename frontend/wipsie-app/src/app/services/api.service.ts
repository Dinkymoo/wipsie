import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { DataPoint, Task, TaskCreate, User, UserCreate } from '../models/database.models';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private baseUrl = environment.apiUrl;

  constructor(private http: HttpClient) { }

  // User endpoints
  getUsers(limit?: number, offset?: number): Observable<User[]> {
    let params = new HttpParams();
    if (limit) params = params.set('limit', limit.toString());
    if (offset) params = params.set('offset', offset.toString());
    
    return this.http.get<User[]>(`${this.baseUrl}/users`, { params });
  }

  getUser(userId: number): Observable<User> {
    return this.http.get<User>(`${this.baseUrl}/users/${userId}`);
  }

  createUser(user: UserCreate): Observable<User> {
    return this.http.post<User>(`${this.baseUrl}/users`, user);
  }

  // Task endpoints
  getTasks(limit?: number, offset?: number, status?: string, userId?: number): Observable<Task[]> {
    let params = new HttpParams();
    if (limit) params = params.set('limit', limit.toString());
    if (offset) params = params.set('offset', offset.toString());
    if (status) params = params.set('status', status);
    if (userId) params = params.set('user_id', userId.toString());
    
    return this.http.get<Task[]>(`${this.baseUrl}/tasks`, { params });
  }

  getTask(taskId: number): Observable<Task> {
    return this.http.get<Task>(`${this.baseUrl}/tasks/${taskId}`);
  }

  createTask(task: TaskCreate): Observable<Task> {
    return this.http.post<Task>(`${this.baseUrl}/tasks`, task);
  }

  updateTask(taskId: number, task: Partial<Task>): Observable<Task> {
    return this.http.put<Task>(`${this.baseUrl}/tasks/${taskId}`, task);
  }

  deleteTask(taskId: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/tasks/${taskId}`);
  }

  // Data point endpoints
  getDataPoints(limit?: number, offset?: number, taskId?: number, dataType?: string): Observable<DataPoint[]> {
    let params = new HttpParams();
    if (limit) params = params.set('limit', limit.toString());
    if (offset) params = params.set('offset', offset.toString());
    if (taskId) params = params.set('task_id', taskId.toString());
    if (dataType) params = params.set('data_type', dataType);
    
    return this.http.get<DataPoint[]>(`${this.baseUrl}/data-points`, { params });
  }

  createDataPoint(dataPoint: Partial<DataPoint>): Observable<DataPoint> {
    return this.http.post<DataPoint>(`${this.baseUrl}/data-points`, dataPoint);
  }

  // Analytics endpoints
  getUserStats(): Observable<Record<string, unknown>> {
    return this.http.get<Record<string, unknown>>(`${this.baseUrl}/analytics/user-stats`);
  }

  getTaskCompletion(): Observable<Record<string, unknown>> {
    return this.http.get<Record<string, unknown>>(`${this.baseUrl}/analytics/task-completion`);
  }
}
