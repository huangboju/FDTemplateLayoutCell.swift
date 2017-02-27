
Pod::Spec.new do |s|

  s.name         = "FDTemplateLayoutCell"
  s.summary      = "It is translation of the UITableView-FDTemplateLayoutCell by Swift"
  s.homepage     = "https://github.com/huangboju/FDTemplateLayoutCell.swift"
  s.license      = "MIT"
  s.author             = { "huangboju" => "529940945@qq.com" }
  s.platform     = :ios,'8.0'
  s.source       = { :git => "https://github.com/huangboju/FDTemplateLayoutCell.swift.git", :tag => "#{s.version}" }
  s.source_files  = "Classes/**/*.swift"
  s.framework  = "UIKit"
  s.requires_arc = true
end
