import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { DataPoint, Task, User } from '../../models/database.models';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  users: User[] = [];
  tasks: Task[] = [];
  dataPoints: DataPoint[] = [];
  loading = true;
  error: string | null = null;

  constructor(private apiService: ApiService) {}

  ngOnInit(): void {
    this.loadData();
  }

  private loadData(): void {
    this.loading = true;
    this.error = null;

    // Load all data in parallel
    Promise.all([
      this.apiService.getUsers(10).toPromise(),
      this.apiService.getTasks(20).toPromise(),
      this.apiService.getDataPoints(30).toPromise()
    ]).then(([users, tasks, dataPoints]) => {
      this.users = users || [];
      this.tasks = tasks || [];
      this.dataPoints = dataPoints || [];
      this.loading = false;
    }).catch((error) => {
      console.error('Error loading data:', error);
      this.error = 'Failed to load data from backend';
      this.loading = false;
    });
  }

  getUserTaskCount(userId: number): number {
    return this.tasks.filter(task => task.user_id === userId).length;
  }

  getTasksByStatus(status: string): Task[] {
    return this.tasks.filter(task => task.status === status);
  }

  getDataPointsByType(type: string): DataPoint[] {
    return this.dataPoints.filter(dp => dp.data_type === type);
  }

  refreshData(): void {
    this.loadData();
  }
}
