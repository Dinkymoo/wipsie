export interface User {
  id: number;
  username: string;
  email: string;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: number;
  user_id: number;
  title: string;
  description?: string;
  status: 'todo' | 'in_progress' | 'done';
  priority: number;
  due_date?: string;
  created_at: string;
  updated_at: string;
}

export interface DataPoint {
  id: number;
  task_id: number;
  data_type: string;
  value_json: Record<string, unknown>;
  meta_data: Record<string, unknown>;
  timestamp: string;
  created_at: string;
}

export interface UserCreate {
  username: string;
  email: string;
  password_hash: string;
}

export interface TaskCreate {
  user_id: number;
  title: string;
  description?: string;
  status?: string;
  priority?: number;
  due_date?: string;
}
