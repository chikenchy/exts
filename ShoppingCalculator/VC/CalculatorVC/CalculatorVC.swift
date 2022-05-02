import UIKit
import CoreData
import GoogleMobileAds
import SideMenu

final class Calculator {
    var items = [MartItem]()
    var history: History?
    
    func load(history: History) {
        self.history = history
        
        items.removeAll()
        if let martItems = history.martItems as? Set<MartItem> {
            items.append(contentsOf: martItems)
        }
    }
    
    func add(count: Int64, price: Double, name: String?) {
        let item = MartItem(context: CoreDataManager.shared.context)
        item.count = count
        item.price = price
        item.name = name
        item.createdAt = Date()
        
        if self.history == nil {
            let new = History(context: CoreDataManager.shared.context)
            new.id = UUID()
            new.createdAt = Date()
            self.history = new
        }
        
        self.history?.updatedAt = Date()
        self.history?.addToMartItems(item)
        
        items.append(item)
    }
    
    func sum() -> String {
        var sum:Decimal = Decimal(0)
        for item in items {
            let add = Decimal(item.price) * Decimal(item.count)
            sum += add
        }
        return sum.description
    }
    
    func clear() {
        if let history = self.history {
            history.willSave()
            
            self.history = nil
        }
        
        items.removeAll()
        
        CoreDataManager.shared.saveContext()
    }
}

enum BtnType: Equatable {
    case digit(str: String)
    case allClear
    case clear
    case price
    case count
    case name
    case dot
    case upsert
    case delete
}

enum SelectType: Equatable {
    case name
    case price
    case count
}

final class CalculatorVC: UIViewController {
    static var shared: CalculatorVC!
    
    override var prefersStatusBarHidden: Bool { true }
    
    var selectedItemIndexPath: IndexPath? {
        didSet {
            if selectedItemIndexPath == nil {
                addBtn.setTitle("✓", for: .normal)
            } else {
                addBtn.setTitle("☑︎", for: .normal)
            }
        }
    }
    
    private func updateDotBtn() {
        if selectType == .price {
            dotBtn.isEnabled = price.contains(".") == false
        } else {
            dotBtn.isEnabled = false
        }
    }
    
    
    let calculator = Calculator()
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var digit0: UIButton!
    @IBOutlet weak var digit00: UIButton!
    @IBOutlet weak var dotBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    
    @IBOutlet weak var digit1: UIButton!
    @IBOutlet weak var digit2: UIButton!
    @IBOutlet weak var digit3: UIButton!
    @IBOutlet weak var priceOrCountBtn: UIButton!
    
    @IBOutlet weak var digit4: UIButton!
    @IBOutlet weak var digit5: UIButton!
    @IBOutlet weak var digit6: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    
    @IBOutlet weak var digit7: UIButton!
    @IBOutlet weak var digit8: UIButton!
    @IBOutlet weak var digit9: UIButton!
    @IBOutlet weak var allClearBtn: UIButton!
    
    @IBOutlet weak var nameLbl: UITextField!
    @IBOutlet weak var priceLbl: UITextField!
    @IBOutlet weak var countLbl: UITextField!
    
    var name: String? {
        get { nameLbl.text }
        set { nameLbl.text = newValue }
    }
    
    var price: String = "0" {
        didSet {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = .currency
            currencyFormatter.locale = Locale.current
            currencyFormatter.maximumSignificantDigits = 100
            
            priceLbl.text = "\(currencyFormatter.currencySymbol!)\(price)"
            
            updateDotBtn()
        }
    }
    var count: String = "1" {
        didSet {
            if Int64(count) == nil{
                count = "0"
            }
            countLbl.text = "×\(Int64(count)!)"
        }
    }
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    private func sharedInit() {
        CalculatorVC.shared = self
    }
    
    func allClear() {
        let vc = UIAlertController(title: nil, message: "전체 삭제하시겠습니까?", preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            self.clearAll()
        }))
        vc.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onTouchUpInside_Btn(_ sender: UIButton) {
        if nameLbl.isEditing {
            return
        }
        
        let btnType: BtnType?
        switch sender.titleLabel!.text {
        case "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "00":
            let str = sender.titleLabel!.text!
            btnType = .digit(str: str)
        case ".":
            btnType = .dot
        case "Del":
            btnType = .delete
        case "C":
            btnType = .clear
        case "AC":
            btnType = .allClear
        case "$":
            btnType = .price
        case "×":
            btnType = .count
        case "✎":
            btnType = .name
        case "✓", "☑︎":
            btnType = .upsert
        default:
            fatalError()
        }
        
        switch btnType! {
        case .digit(let str):
            switch str {
            case "0", "00":
                if selectType == .price {
                    if price.isEmpty {
                        price += "0"
                    } else if price == "0" {
                        break
                    } else {
                        price += str
                    }
                } else if selectType == .count {
                    if count.isEmpty {
                        count += "0"
                    } else if count == "0" {
                        break
                    } else {
                        count += str
                    }
                }
            case "1", "2", "3", "4", "5", "6", "7", "8", "9":
                if selectType == .price {
                    price += str
                } else if selectType == .count {
                    count += str
                }
            default: break
            }
        case .dot:
            if selectType == .price {
                if price == "" {
                    price = "0."
                } else {
                    price += "."
                }
            }
        case .allClear:
            allClear()
        case .clear:
            clearCurrent()
        case .price, .count, .name:
            switchsPriceOrCountBtn()
        case .upsert:
            if let priceFloat = Float(price) {
                if priceFloat == 0 && name?.count ?? 0 < 1 {
                    nameLbl.becomeFirstResponder()
                    return
                }
            }
            
            guard let countInt = Int64(count), countInt > 0 else {
                selectType = .count
                return
            }
            
            if let selectedItemIndexPath = selectedItemIndexPath {
                let item = calculator.items[selectedItemIndexPath.row]
                item.count = Int64(count) ?? 0
                item.price = Double(price) ?? 0
                item.name = name
                item.createdAt = Date()
                
                self.selectedItemIndexPath = nil
                
                tableView.beginUpdates()
                tableView.reloadRows(at: [ selectedItemIndexPath ], with: .automatic)
                updateSum()
                tableView.endUpdates()
            } else {
                calculator.add(count: Int64(count) ?? 0, price: Double(price) ?? 0, name: name)
                
                tableView.beginUpdates()
                tableView.insertRows(at: [IndexPath(row: calculator.items.count-1, section: 0)], with: .automatic)
                updateSum()
                tableView.endUpdates()
                
                tableView.scrollToRow(at: IndexPath(row: calculator.items.count-1, section: 0), at: UITableView.ScrollPosition(rawValue: 0)!, animated: true)
            }
            
            clearCurrent()
            
            selectType = .price
        case .delete:
            switch selectType {
            case .count:
                if count.count > 0 {
                    count.removeLast()
                }
            case .price:
                if price.count > 0 {
                    if price == "0." {
                        price.removeAll()
                    } else {
                        price.removeLast()
                    }
                }
            default: break
            }
        }
    }
    
    private func clearCurrent() {
        price = "0"
        count = "1"
        name = nil
    }
    
    private func clearAll() {
        clearCurrent()
        calculator.clear()
        tableView.reloadData()
        if let selectedItemIndexPath = selectedItemIndexPath {
            tableView.deselectRow(at: selectedItemIndexPath, animated: false)
            self.selectedItemIndexPath = nil
        }
    }
    
    var selectType: SelectType? {
        didSet {
            if selectType == .price {
                price = ""
                
                priceOrCountBtn.setTitle("×", for: .normal)
                priceOrCountBtn.titleLabel!.sizeToFit()
                
                nameLbl.backgroundColor = .clear
                priceLbl.backgroundColor = .systemFill
                countLbl.backgroundColor = .clear
            } else if selectType == .count {
                count = ""
                
                priceOrCountBtn.setTitle("✎", for: .normal)
                priceOrCountBtn.titleLabel!.sizeToFit()
                
                nameLbl.backgroundColor = .clear
                priceLbl.backgroundColor = .clear
                countLbl.backgroundColor = .systemFill
            } else if selectType == .name {
                priceOrCountBtn.setTitle("$", for: .normal)
                priceOrCountBtn.titleLabel!.sizeToFit()
                
                nameLbl.backgroundColor = .systemFill
                priceLbl.backgroundColor = .clear
                countLbl.backgroundColor = .clear
            } else {
                priceOrCountBtn.setTitle("$", for: .normal)
                priceOrCountBtn.titleLabel!.sizeToFit()
                
                nameLbl.backgroundColor = .clear
                priceLbl.backgroundColor = .clear
                countLbl.backgroundColor = .clear
            }
            updateDotBtn()
        }
    }
    
    private func switchsPriceOrCountBtn() {
        switch selectType {
        case .price:
            selectType = .count
        case .count:
            selectType = .name
            nameLbl.becomeFirstResponder()
        case .name, .none:
            selectType = .price
        }
    }
    
    override func loadView() {
        super.loadView()
        
        tableView.delegate = self
        tableView.dataSource = self
        registerCells()
        
        priceLbl.delegate = self
        countLbl.delegate = self
        nameLbl.delegate = self
        
        clearCurrent()
        selectType = .price
        selectedItemIndexPath = nil
        
        digit0.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit00.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        dotBtn.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        addBtn.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit1.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit2.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit3.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        priceOrCountBtn.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit4.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit5.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit6.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit7.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit8.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        digit9.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        clearBtn.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        allClearBtn.addTarget(self, action: #selector(onTouchUpInside_Btn), for: .touchUpInside)
        
        bannerView.rootViewController = self
        bannerView.delegate = self
        
        // setup SideMenu
        let sideVC = HistoryTableViewController()
        let menuNC = SideMenuNavigationController(rootViewController:sideVC)
        menuNC.statusBarEndAlpha = 0
        menuNC.menuWidth = 200
        
        SideMenuManager.default.leftMenuNavigationController = menuNC
//        SideMenuManager.default.addPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let req = GADRequest()
        bannerView.load(req)
        bannerView.isHidden = true
    }
    
    func updateSum() {
        let sumFooterView = tableView.footerView(forSection: 0) as! CalculatorSumFooterView
        sumFooterView.sum = calculator.sum()
    }
    
}

extension CalculatorVC {
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
    }
    
}