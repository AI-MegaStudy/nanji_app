import SwiftUI

// MARK: - Model
struct ParkingLot: Identifiable {
    let id: String
    let name: String
    let distance: Double
    let available: Int
    let total: Int
    let estimatedTime: Int
    
    var status: Status {
        let ratio = Double(available) / Double(total)
        if ratio > 0.5 { return .available }
        if ratio > 0.2 { return .moderate }
        return .busy
    }
    
    enum Status {
        case available, moderate, busy
        
        var label: String {
            switch self {
            case .available: return "여유"
            case .moderate: return "보통"
            case .busy: return "혼잡"
            }
        }
        
        var color: Color {
            switch self {
            case .available: return Color(hex: "#6FA858")
            case .moderate: return Color(hex: "#E8D878")
            case .busy: return Color(hex: "#CD6355")
            }
        }
        
        var background: Color {
            color.opacity(0.1)
        }
        
        var border: Color {
            color.opacity(0.3)
        }
    }
}

// MARK: - View
struct RecommendPage: View {
    
    let parkingLots: [ParkingLot] = [
        ParkingLot(id: "1", name: "난지 캠핑장 주차장", distance: 0.8, available: 89, total: 150, estimatedTime: 2),
        ParkingLot(id: "2", name: "하늘공원 주차장", distance: 1.2, available: 45, total: 120, estimatedTime: 3),
        ParkingLot(id: "3", name: "월드컵공원 주차장", distance: 1.5, available: 12, total: 180, estimatedTime: 4)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 카드
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(Color(hex: "#7DD3FC"))
                    
                    Text("대체 주차장")
                        .font(.headline)
                }
                
                VStack(spacing: 12) {
                    ForEach(parkingLots) { lot in
                        ParkingCard(lot: lot)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 4)
            
            // 버튼
            Button(action: {
                // 지도 이동 (예: 카카오맵)
            }) {
                HStack {
                    Image(systemName: "mappin")
                    Text("지도에서 전체 보기")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#7DD3FC"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - 카드 컴포넌트
struct ParkingCard: View {
    let lot: ParkingLot
    
    var occupancyRate: Double {
        Double(lot.available) / Double(lot.total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 상단
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    
                    Text(lot.name)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label("\(lot.distance, specifier: "%.1f")km", systemImage: "location")
                        Label("약 \(lot.estimatedTime)분", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(lot.status.label)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(lot.status.background)
                    .foregroundColor(lot.status.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(lot.status.border, lineWidth: 1)
                    )
                    .cornerRadius(20)
            }
            
            // 남은 자리
            HStack {
                Text("남은 자리")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(lot.available) / \(lot.total)")
                    .font(.headline)
            }
            
            // 프로그레스 바
            ProgressView(value: occupancyRate)
                .tint(lot.status.color)
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
        .cornerRadius(12)
        .onTapGesture {
            // 상세보기 or 지도 이동
        }
    }
}

// MARK: - HEX Color 지원
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF,
                     (int >> 8) & 0xFF,
                     int & 0xFF)
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}