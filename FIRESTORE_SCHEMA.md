# 🗄️ Firestore Schema: Fleet Management

## Collection: `fleet`
Stores authentication credentials and metadata for campus vehicles.

### 📄 Document Structure
**Document ID:** `vehicleId` (e.g., `BUS-01`, `SHUTTLE-01`)

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `pin` | String | ✅ Yes | Access PIN for driver login. |
| `plateNumber` | String | ❌ No | Vehicle license plate. |
| `status` | String | ✅ Yes | `active`, `maintenance`, `retired`. |
| `type` | String | ✅ Yes | `bus`, `shuttle`, `van`. |
| `currentRoute` | String | ❌ No | ID of the active route (if any). |

### 📝 Example JSON
```json
// Path: fleet/BUS-01
{
  "pin": "1234",
  "plateNumber": "AS-16-C-1234",
  "status": "active",
  "type": "bus"
}
```

## 🚀 Setup
To seed this data, import `lib/utils/firestore_seeder.dart` and call:
`await FirestoreSeeder.seedFleet();`
from your `main.dart` or a temporary button.