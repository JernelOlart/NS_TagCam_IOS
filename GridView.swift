import UIKit

class GridView: UIView {
    
    var lineOpacity: Float = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.white.withAlphaComponent(CGFloat(lineOpacity)).cgColor)
        
        let columnWidth = rect.width / 3.0
        let rowHeight = rect.height / 3.0
        
        // Draw vertical lines
        for i in 1...2 {
            let x = CGFloat(i) * columnWidth
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Draw horizontal lines
        for i in 1...2 {
            let y = CGFloat(i) * rowHeight
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        context.strokePath()
    }
}
