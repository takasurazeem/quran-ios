//
//  ViewConstrainer.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/21/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit

public class ViewConstrainer {
    // MARK: Lifecycle

    init(view: UIView, chain: [NSLayoutConstraint]) {
        self.view = view
        self.chain = chain
    }

    // MARK: Public

    public internal(set) var chain: [NSLayoutConstraint]

    // MARK: Internal

    let view: UIView
}

extension ViewConstrainer {
    private func commonAncestor(view1: UIView, view2: UIView) -> UIView {
        var ancestor = view1
        while !view2.isDescendant(of: ancestor) {
            guard let parent = view1.superview else {
                fatalError("There is no common ancestor between views \(view1) and \(view2).")
            }
            ancestor = parent
        }
        return ancestor
    }

    private func commonAncestor(views: [UIView]) -> UIView {
        var ancestor = view
        for view in views {
            ancestor = commonAncestor(view1: ancestor, view2: view)
        }
        return ancestor
    }

    private func constraintSelf(on attribute: NSLayoutConstraint.Attribute, value: CGFloat) -> SingleConstrainer {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: attribute,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: value
        )
        view.addConstraint(constraint)
        return SingleConstrainer(view: view, constraint: constraint, chain: [constraint])
    }

    private func align(views: [UIView], by value: CGFloat, on attribute: NSLayoutConstraint.Attribute) -> GroupConstrainer {
        assert(!views.isEmpty, "should have at least 1 view")

        let ancestor = commonAncestor(views: views)
        var constraints: [NSLayoutConstraint] = []
        for view in views {
            let constraint = NSLayoutConstraint(
                item: self.view,
                attribute: attribute,
                relatedBy: .equal,
                toItem: view,
                attribute: attribute,
                multiplier: 1,
                constant: value
            )
            ancestor.addConstraint(constraint)
            constraints.append(constraint)
        }
        return GroupConstrainer(view: view, constraints: constraints, chain: constraints)
    }

    private func constraintToSuperview(
        on attribute: NSLayoutConstraint.Attribute,
        by value: CGFloat,
        superviewFirst: Bool,
        usesMargins: Bool
    ) -> SingleConstrainer {
        let marginalAttribute: NSLayoutConstraint.Attribute = if usesMargins {
            switch attribute {
            case .leading: .leadingMargin
            case .trailing: .trailingMargin
            case .top: .topMargin
            case .bottom: .bottomMargin
            default: attribute
            }
        } else {
            attribute
        }
        guard let superview = view.superview else {
            fatalError("View \(view) should have been added as subview to another view before constraining it.")
        }
        let constraint = NSLayoutConstraint(
            item: superviewFirst ? superview : view,
            attribute: superviewFirst ? marginalAttribute : attribute,
            relatedBy: .equal,
            toItem: !superviewFirst ? superview : view,
            attribute: !superviewFirst ? marginalAttribute : attribute,
            multiplier: 1,
            constant: value
        )
        superview.addConstraint(constraint)
        return SingleConstrainer(view: view, constraint: constraint, chain: [constraint])
    }

    private func makeLine(
        views: [UIView],
        by value: CGFloat,
        on firstAttribute: NSLayoutConstraint.Attribute,
        and secondAttribute: NSLayoutConstraint.Attribute
    ) -> GroupConstrainer {
        assert(!views.isEmpty, "should have at least 1 view")

        let ancestor = commonAncestor(views: views)
        var constraints: [NSLayoutConstraint] = []
        for (view1, view2) in zip([view] + views, views) {
            let constraint = NSLayoutConstraint(
                item: view1,
                attribute: firstAttribute,
                relatedBy: .equal,
                toItem: view2,
                attribute: secondAttribute,
                multiplier: 1,
                constant: value
            )
            ancestor.addConstraint(constraint)
            constraints.append(constraint)
        }
        return GroupConstrainer(view: view, constraints: constraints, chain: constraints)
    }
}

extension ViewConstrainer {
    @discardableResult
    public func width(by value: CGFloat) -> SingleConstrainer {
        constraintSelf(on: .width, value: value)
    }

    @discardableResult
    public func width(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: width(to: [view], by: value))
    }

    @discardableResult
    public func width(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .width)
    }

    @discardableResult
    public func height(by value: CGFloat) -> SingleConstrainer {
        constraintSelf(on: .height, value: value)
    }

    @discardableResult
    public func height(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: height(to: [view], by: value))
    }

    @discardableResult
    public func height(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .height)
    }

    @discardableResult
    public func size(by size: CGSize) -> GroupConstrainer {
        GroupConstrainer(constrainer: self, group: [width(by: size.width), height(by: size.height)])
    }

    @discardableResult
    public func size(to view: UIView, by value: CGSize = .zero) -> GroupConstrainer {
        size(to: [view], by: value)
    }

    @discardableResult
    public func size(to views: [UIView], by size: CGSize = .zero) -> GroupConstrainer {
        let group = [width(to: views, by: size.width), height(to: views, by: size.height)]
        return GroupConstrainer(constrainer: self, group: group)
    }

    @discardableResult
    public func size(by dimension: CGFloat) -> GroupConstrainer {
        size(by: CGSize(width: dimension, height: dimension))
    }

    @discardableResult
    public func size(to view: UIView, by dimension: CGFloat) -> GroupConstrainer {
        size(to: view, by: CGSize(width: dimension, height: dimension))
    }

    @discardableResult
    public func size(to views: [UIView], by dimension: CGFloat) -> GroupConstrainer {
        size(to: views, by: CGSize(width: dimension, height: dimension))
    }
}

extension ViewConstrainer {
    @discardableResult
    public func leading(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .leading, by: value, superviewFirst: false, usesMargins: usesMargins)
    }

    @discardableResult
    public func leading(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: leading(to: [view], by: value))
    }

    @discardableResult
    public func leading(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .leading)
    }

    @discardableResult
    public func left(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .left, by: value, superviewFirst: false, usesMargins: usesMargins)
    }

    @discardableResult
    public func left(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: left(to: [view], by: value))
    }

    @discardableResult
    public func left(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .left)
    }

    @discardableResult
    public func trailing(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .trailing, by: value, superviewFirst: true, usesMargins: usesMargins)
    }

    @discardableResult
    public func trailing(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: trailing(to: [view], by: value))
    }

    @discardableResult
    public func trailing(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .trailing)
    }

    @discardableResult
    public func right(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .right, by: value, superviewFirst: true, usesMargins: usesMargins)
    }

    @discardableResult
    public func right(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: right(to: [view], by: value))
    }

    @discardableResult
    public func right(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .right)
    }

    @discardableResult
    public func top(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .top, by: value, superviewFirst: false, usesMargins: usesMargins)
    }

    @discardableResult
    public func top(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: top(to: [view], by: value))
    }

    @discardableResult
    public func top(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .top)
    }

    @discardableResult
    public func bottom(by value: CGFloat = 0, usesMargins: Bool = false) -> SingleConstrainer {
        constraintToSuperview(on: .bottom, by: value, superviewFirst: true, usesMargins: usesMargins)
    }

    @discardableResult
    public func bottom(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: bottom(to: [view], by: value))
    }

    @discardableResult
    public func bottom(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .bottom)
    }

    @discardableResult
    public func horizontalEdges(leading: CGFloat = 0, trailing: CGFloat = 0, usesMargins: Bool = false) -> GroupConstrainer {
        let group = [self.leading(by: leading, usesMargins: usesMargins), self.trailing(by: trailing, usesMargins: usesMargins)]
        return GroupConstrainer(constrainer: self, group: group)
    }

    @discardableResult
    public func horizontalEdges(inset: CGFloat, usesMargins: Bool = false) -> GroupConstrainer {
        horizontalEdges(leading: inset, trailing: inset, usesMargins: usesMargins)
    }

    @discardableResult
    public func verticalEdges(top: CGFloat = 0, bottom: CGFloat = 0, usesMargins: Bool = false) -> GroupConstrainer {
        let group = [self.top(by: top, usesMargins: usesMargins), self.bottom(by: bottom, usesMargins: usesMargins)]
        return GroupConstrainer(constrainer: self, group: group)
    }

    @discardableResult
    public func verticalEdges(inset: CGFloat, usesMargins: Bool = false) -> GroupConstrainer {
        verticalEdges(top: inset, bottom: inset, usesMargins: usesMargins)
    }

    @discardableResult
    public func edges(
        leading: CGFloat = 0,
        trailing: CGFloat = 0,
        top: CGFloat = 0,
        bottom: CGFloat = 0,
        usesMargins: Bool = false
    ) -> GroupConstrainer {
        let group = [horizontalEdges(leading: leading, trailing: trailing, usesMargins: usesMargins),
                     verticalEdges(top: top, bottom: bottom, usesMargins: usesMargins)]
        return GroupConstrainer(constrainer: self, group: group)
    }

    @discardableResult
    public func edges(horizontalInset: CGFloat, verticalInset: CGFloat, usesMargins: Bool = false) -> GroupConstrainer {
        edges(leading: horizontalInset, trailing: horizontalInset, top: verticalInset, bottom: verticalInset, usesMargins: usesMargins)
    }

    @discardableResult
    public func edges(inset: CGFloat, usesMargins: Bool = false) -> GroupConstrainer {
        edges(leading: inset, trailing: inset, top: inset, bottom: inset, usesMargins: usesMargins)
    }
}

extension ViewConstrainer {
    @discardableResult
    public func centerX(by value: CGFloat = 0) -> SingleConstrainer {
        constraintToSuperview(on: .centerX, by: value, superviewFirst: false, usesMargins: false)
    }

    @discardableResult
    public func centerX(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: centerX(to: [view], by: value))
    }

    @discardableResult
    public func centerX(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .centerX)
    }

    @discardableResult
    public func centerY(by value: CGFloat = 0) -> SingleConstrainer {
        constraintToSuperview(on: .centerY, by: value, superviewFirst: false, usesMargins: false)
    }

    @discardableResult
    public func centerY(to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: centerY(to: [view], by: value))
    }

    @discardableResult
    public func centerY(to views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        align(views: views, by: value, on: .centerY)
    }

    @discardableResult
    public func center(x: CGFloat = 0, y: CGFloat = 0) -> GroupConstrainer {
        GroupConstrainer(constrainer: self, group: [centerX(by: x), centerY(by: y)])
    }

    @discardableResult
    public func center(to view: UIView, byX x: CGFloat = 0, byY y: CGFloat = 0) -> GroupConstrainer {
        center(to: [view], byX: x, byY: y)
    }

    @discardableResult
    public func center(to views: [UIView], byX x: CGFloat = 0, byY y: CGFloat = 0) -> GroupConstrainer {
        GroupConstrainer(constrainer: self, group: [centerX(to: views, by: x), centerY(to: views, by: y)])
    }
}

extension ViewConstrainer {
    @discardableResult
    public func align(on attribute: NSLayoutConstraint.Attribute, to view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: align(views: [view], by: value, on: attribute))
    }

    @discardableResult
    public func alignEdges(to view: UIView) -> GroupConstrainer {
        GroupConstrainer(constrainer: self, group: [
            align(on: .leading, to: view),
            align(on: .trailing, to: view),
            align(on: .top, to: view),
            align(on: .bottom, to: view),
        ])
    }
}

extension ViewConstrainer {
    @discardableResult
    public func horizontalLine(_ view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: horizontalLine([view], by: value))
    }

    @discardableResult
    public func horizontalLine(_ views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        makeLine(views: views, by: value, on: .trailing, and: .leading)
    }

    @discardableResult
    public func verticalLine(_ view: UIView, by value: CGFloat = 0) -> SingleConstrainer {
        SingleConstrainer(constrainer: self, group: verticalLine([view], by: value))
    }

    @discardableResult
    public func verticalLine(_ views: [UIView], by value: CGFloat = 0) -> GroupConstrainer {
        makeLine(views: views, by: value, on: .bottom, and: .top)
    }
}
