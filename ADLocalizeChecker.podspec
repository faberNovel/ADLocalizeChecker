Pod::Spec.new do |spec|
  spec.name         = 'ADLocalizeChecker'
  spec.version      = '0.6.4'
  spec.authors      = 'FABERNOVEL'
  spec.homepage     = 'https://github.com/faberNovel/ADLocalizeChecker'
  spec.summary      = 'FABERNOVEL\'s iOS Localized Checker'
  spec.license      = { :type => 'Commercial', :text => 'Created and licensed by FABERNOVEL. Copyright 2021 FABERNOVEL. All rights reserved.' }
  spec.source       = { http: "#{spec.homepage}/releases/download/#{spec.version}/LocalizeChecker.zip" }
  spec.ios.deployment_target = '9.0'
  spec.tvos.deployment_target = '9.0'

  # No source files here, we do not want the script file to be compiled in the importing project
  # spec.source_files = ''

  spec.preserve_path = '*'
end
