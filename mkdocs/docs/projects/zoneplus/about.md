# Zone+

# Referencing
After requiring the MainModule, Zone+ modules can be referenced on the client under the HDAdmin directory in ReplicatedStorage, and server in ServerStorage or directly from the MainModule.

| Location                 | Pathway            |
| :--------------     |:--------------   |
| Client       | ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |
| Server       | ``MainModule`` or ``ServerStorage:WaitForChild("HDAdmin"):WaitForChild("Zone+")``   |